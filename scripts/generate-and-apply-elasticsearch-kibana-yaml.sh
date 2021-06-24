#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export ELASTICSEARCH_CN=$(yq e .shared-services-cluster.elasticsearch-fqdn $PARAMS_YAML)
export KIBANA_CN=$(yq e .shared-services-cluster.kibana-fqdn $PARAMS_YAML)
CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/ek/
cp elasticsearch-kibana/*.yaml generated/$CLUSTER_NAME/ek/
cp elasticsearch-kibana/template/*.yaml generated/$CLUSTER_NAME/ek/

yq e -i ".spec.rules[0].host = env(ELASTICSEARCH_CN)" generated/$CLUSTER_NAME/ek/03b-ingress.yaml
yq e -i ".spec.rules[0].host = env(KIBANA_CN)" generated/$CLUSTER_NAME/ek/05-kibana-ingress.yaml 

kubectl apply -f generated/$CLUSTER_NAME/ek/

# Add image pull secret with dockerhub creds
$TKG_LAB_SCRIPTS/add-dockerhub-pull-secret.sh elasticsearch-kibana

#Wait for pod to be ready
while kubectl get po -n elasticsearch-kibana elasticsearch-0 | grep Running ; [ $? -ne 0 ]; do
	echo Elasticsearch is not yet ready
	sleep 5s
done
