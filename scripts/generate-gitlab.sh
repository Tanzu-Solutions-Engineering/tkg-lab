#!/bin/bash -e

CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
GITLAB_BASE_FQDN="$(yq e .shared-services-cluster.name $PARAMS_YAML).$(yq e .subdomain $PARAMS_YAML)"
IAAS=$(yq e .iaas $PARAMS_YAML)
LETS_ENCRYPT_EMAIL=$(yq e .lets-encrypt-acme-email $PARAMS_YAML)
mkdir -p generated/$CLUSTER_NAME/gitlab/

cp gitlab/values-gitlab.yaml generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

# Grab the external IP or name
if [ "$IAAS" = "vsphere" ]; then
  EXT_NAME=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
else
  EXT_NAME=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
fi

sed -i -e "s/GITLAB_BASE_FQDN/$GITLAB_BASE_FQDN/g" generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml
sed -i -e "s/EXTERNAL_LB_IP/$EXT_NAME/g" generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml
sed -i -e "s/CERT_MANAGER_EMAIL/$LETS_ENCRYPT_EMAIL/g" generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml
# Remove original file copy created by sed on mac's.  noop for linux
rm generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml-e
