#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh


CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/app-accelerator


kapp deploy -y -a flux -f https://github.com/fluxcd/flux2/releases/download/v0.15.0/install.yaml \
  --filter '{"not": {"resource": {"kinds": ["NetworkPolicy"]}}}'

PIVOTAL_REGISTRY_URL=$(yq e .pivnet.registry-url $PARAMS_YAML)
PIVOTAL_REGISTRY_USER=$(yq e .pivnet.username $PARAMS_YAML)
PIVOTAL_REGISTRY_PASSWORD=$(yq e .pivnet.password $PARAMS_YAML)

echo ${PIVOTAL_REGISTRY_PASSWORD} | docker login ${PIVOTAL_REGISTRY_URL} -u ${PIVOTAL_REGISTRY_USER} --password-stdin

imgpkg pull -b registry.pivotal.io/app-accelerator/acc-install-bundle:0.2.0 \
  -o /tmp/acc-install-bundle

export acc_registry__username=${PIVOTAL_REGISTRY_USER}
export acc_registry__password=${PIVOTAL_REGISTRY_PASSWORD}
export acc_server__service_type=ClusterIP

ytt -f /tmp/acc-install-bundle/config -f /tmp/acc-install-bundle/values.yml --data-values-env acc  \
| kbld -f /tmp/acc-install-bundle/.imgpkg/images.yml -f- \
| kapp deploy -y -a accelerator -f-

ytt -f ./config-templates/app-accelerator-cert-ytt.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER_NAME/app-accelerator/app-accelerator-cert.yaml
ytt -f ./config-templates/app-accelerator-httpproxy-ytt.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER_NAME/app-accelerator/app-accelerator-httpproxy.yaml

kubectl apply -f generated/$CLUSTER_NAME/app-accelerator/app-accelerator-cert.yaml 
kubectl apply -f generated/$CLUSTER_NAME/app-accelerator/app-accelerator-httpproxy.yaml


kubectl patch deploy -n accelerator-system acc-engine --type=json -p='[{ "op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "4G" }, { "op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "4G" }, { "op":"add", "path": "/spec/template/spec/containers/0/env", "value": [{ "name": "JAVA_TOOL_OPTIONS", "value": "-XX:MaxDirectMemorySize=1G"}]  } ]'


# don't want to move on until the accelerator is reachable.  First wait for the cert to come back, then check the actual endpoint
RESULT=$(kubectl get certificate -n accelerator-system app-accelerator-cert -o json | jq -r '.status.conditions[] | select(.type == "Ready").status')
while [ $RESULT != "True" ]
do 
sleep 5
RESULT=$(kubectl get certificate -n accelerator-system app-accelerator-cert -o json | jq -r '.status.conditions[] | select(.type == "Ready").status')
done

ACCELERATOR_HOSTNAME=$(yq e .app-accelerator.fqdn $PARAMS_YAML)
URL=https://${ACCELERATOR_HOSTNAME}
RESULT=$(curl -ILSso /dev/null -w '%{response_code}' $URL | head -n 1 | cut -d$' ' -f2)
while [ $RESULT != "200" ]
do 
sleep 5
RESULT=$(curl -ILSso /dev/null -w '%{response_code}' $URL | head -n 1 | cut -d$' ' -f2)
done
