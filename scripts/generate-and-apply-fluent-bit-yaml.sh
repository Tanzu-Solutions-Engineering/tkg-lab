#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/set-env.sh

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
  ELASTICSEARCH_PORT=9200
else
  ELASTICSEARCH_CN=$(yq r $PARAMS_YAML shared-services-cluster.elasticsearch-fqdn)
  ELASTICSEARCH_PORT=80
fi

mkdir -p generated/$CLUSTER_NAME/fluent-bit/

# 04-fluent-bit-configmap.yaml
yq read tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml > generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml

if [ `uname -s` = 'Darwin' ];
then
  sed -i '' -e 's/<TKG_CLUSTER_NAME>/'$CLUSTER_NAME'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i '' -e 's/<TKG_INSTANCE_NAME>/'$TKG_ENVIRONMENT_NAME'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i '' -e 's/<FLUENT_ELASTICSEARCH_HOST>/'$ELASTICSEARCH_CN'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i '' -e 's/<FLUENT_ELASTICSEARCH_PORT>/'$ELASTICSEARCH_PORT'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
else
  sed -i -e 's/<TKG_CLUSTER_NAME>/'$CLUSTER_NAME'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i -e 's/<TKG_INSTANCE_NAME>/'$TKG_ENVIRONMENT_NAME'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i -e 's/<FLUENT_ELASTICSEARCH_HOST>/'$ELASTICSEARCH_CN'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
  sed -i -e 's/<FLUENT_ELASTICSEARCH_PORT>/'$ELASTICSEARCH_PORT'/g' generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
fi


kubectl apply -f tkg-extensions/logging/fluent-bit/aws/00-fluent-bit-namespace.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/01-fluent-bit-service-account.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/02-fluent-bit-role.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/03-fluent-bit-role-binding.yaml
# Using modified version below
kubectl apply -f generated/$CLUSTER_NAME/fluent-bit/04-fluent-bit-configmap.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/05-fluent-bit-ds.yaml
