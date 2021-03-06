#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

export CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

export TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)

if [ $(yq e .shared-services-cluster.name $PARAMS_YAML) = $CLUSTER_NAME ];
then
  export ELASTICSEARCH_CN=elasticsearch.elasticsearch-kibana
  export ELASTICSEARCH_PORT="9200"
else
  export ELASTICSEARCH_CN=$(yq e .shared-services-cluster.elasticsearch-fqdn $PARAMS_YAML)
  export ELASTICSEARCH_PORT="80"
fi

mkdir -p generated/$CLUSTER_NAME/fluent-bit/

# 04-fluent-bit-configmap.yaml
cp tkg-extensions/extensions/logging/fluent-bit/elasticsearch/fluent-bit-data-values.yaml.example generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml

yq e -i ".tkg.instance_name = env(TKG_ENVIRONMENT_NAME)" generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
yq e -i ".tkg.cluster_name = env(CLUSTER_NAME)" generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
yq e -i ".fluent_bit.elasticsearch.host = env(ELASTICSEARCH_CN)" generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
yq e -i ".fluent_bit.elasticsearch.port = env(ELASTICSEARCH_PORT)" generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml

add_yaml_doc_seperator generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml

kubectl apply -f tkg-extensions/extensions/logging/fluent-bit/namespace-role.yaml
kubectl create secret generic fluent-bit-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml -n tanzu-system-logging -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f tkg-extensions/extensions/logging/fluent-bit/fluent-bit-extension.yaml

while kubectl get app fluent-bit -n tanzu-system-logging | grep fluent-bit | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo Fluent-bit extension is not yet ready
	sleep 5s
done   
