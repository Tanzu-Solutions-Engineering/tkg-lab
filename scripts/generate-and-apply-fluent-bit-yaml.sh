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

export CONFIG_OUTPUTS=$(cat << EOF
[OUTPUT]
  Name              es
  Match             *
  Host              $ELASTICSEARCH_CN
  Port              $ELASTICSEARCH_PORT
  Logstash_Format   On
  Replace_Dots      On
  Retry_Limit       False
  Buffer_Size       False
  tls               Off
EOF
)
export CONFIG_FILTERS=$(cat << EOF
[FILTER]
  Name                kubernetes
  Match               kube.*
  Kube_URL            https://kubernetes.default.svc:443
  Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
  Kube_Tag_Prefix     kube.var.log.containers.
  Merge_Log           On
  Merge_Log_Key       log_processed
  K8S-Logging.Parser  On
  K8S-Logging.Exclude On

[FILTER]
  Name                record_modifier
  Match               *
  Record tkg_cluster  $CLUSTER_NAME
  Record tkg_instance $TKG_ENVIRONMENT_NAME
EOF
)

yq e ".fluent_bit.config.outputs = strenv(CONFIG_OUTPUTS)" --null-input > generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
yq e -i ".fluent_bit.config.filters = strenv(CONFIG_FILTERS)" generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml

VERSION=$(tanzu package available list fluent-bit.tanzu.vmware.com -oyaml | yq eval ".[0].version" -)
tanzu package install fluent-bit \
    --package-name fluent-bit.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/fluent-bit/fluent-bit-data-values.yaml
