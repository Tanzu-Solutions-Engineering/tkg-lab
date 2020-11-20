#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

TKG_ENVIRONMENT_NAME=$(yq r $PARAMS_YAML environment-name)

if [ $(yq r $PARAMS_YAML shared-services-cluster.name) = $CLUSTER_NAME ];
then
  ELASTICSEARCH_CN=elasticsearch.elasticsearch-kibana
  ELASTICSEARCH_PORT="9200"
else
  ELASTICSEARCH_CN=$(yq r $PARAMS_YAML shared-services-cluster.elasticsearch-fqdn)
  ELASTICSEARCH_PORT="80"
fi

mkdir -p generated/$CLUSTER_NAME/fluent-bit/

# 04-fluent-bit-configmap.yaml
yq read tkg-extensions/extensions/logging/fluent-bit/elasticsearch/fluent-bit-data-values.yaml.example > generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml

yq write generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -i "tkg.instance_name" $TKG_ENVIRONMENT_NAME
yq write generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -i "tkg.cluster_name" $CLUSTER_NAME
yq write generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -i "fluent_bit.elasticsearch.host" $ELASTICSEARCH_CN
yq write generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -i "fluent_bit.elasticsearch.port" $ELASTICSEARCH_PORT --style single

# Add in the document seperator that yq removes
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' '3i\
  ---\
  ' generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
else
  sed -i -e '3i\
  ---\
  ' generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
fi

kubectl apply -f tkg-extensions/extensions/logging/fluent-bit/namespace-role.yaml
kubectl create secret generic fluent-bit-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -n tanzu-system-logging -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f tkg-extensions/extensions/logging/fluent-bit/fluent-bit-extension.yaml

while kubectl get app fluent-bit -n tanzu-system-logging | grep fluent-bit | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo Fluent-bit extension is not yet ready
	sleep 5s
done   
