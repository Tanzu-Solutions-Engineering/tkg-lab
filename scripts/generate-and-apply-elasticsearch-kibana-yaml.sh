#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

ELASTICSEARCH_CN=$(yq r $PARAMS_YAML shared-services-cluster.elasticsearch-fqdn)
KIBANA_CN=$(yq r $PARAMS_YAML shared-services-cluster.kibana-fqdn)
CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/ek/
cp $TKG_LAB_SCRIPTS/../elasticsearch-kibana/*.yaml generated/$CLUSTER_NAME/ek/
cp $TKG_LAB_SCRIPTS/../elasticsearch-kibana/template/*.yaml generated/$CLUSTER_NAME/ek/

yq write -d0 generated/$CLUSTER_NAME/ek/03b-ingress.yaml -i "spec.rules[0].host" $ELASTICSEARCH_CN
yq write -d2 generated/$CLUSTER_NAME/ek/04-kibana.yaml -i "spec.rules[0].host" $KIBANA_CN

kubectl apply -f generated/$CLUSTER_NAME/ek/

#Wait for pod to be ready
while kubectl get po -n elasticsearch-kibana elasticsearch-0 | grep Running ; [ $? -ne 0 ]; do
	echo Elasticsearch is not yet ready
	sleep 5s
done
