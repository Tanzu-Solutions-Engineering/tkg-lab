#!/bin/bash -e

ELASTICSEARCH_CN=$(yq r params.yaml shared-services-cluster.elasticsearch-fqdn)
KIBANA_CN=$(yq r params.yaml shared-services-cluster.kibana-fqdn)
CLUSTER_NAME=$(yq r params.yaml shared-services-cluster.name)

mkdir -p generated/$CLUSTER_NAME/ek/
cp clusters/mgmt/elasticsearch-kibana/*.yaml generated/$CLUSTER_NAME/ek/
cp clusters/mgmt/elasticsearch-kibana/generated/*.yaml generated/$CLUSTER_NAME/ek/

yq write -d0 generated/$CLUSTER_NAME/ek/03b-ingress.yaml -i "spec.rules[0].host" $ELASTICSEARCH_CN
yq write -d2 generated/$CLUSTER_NAME/ek/04-kibana.yaml -i "spec.rules[0].host" $KIBANA_CN

kubectl apply -f generated/$CLUSTER_NAME/ek/

#Wait for cert to be ready
while kubectl get po -n elasticsearch-kibana elasticsearch-0 | grep Running ; [ $? -ne 0 ]; do
	echo Elasticsearch is not yet ready
	sleep 5s
done   