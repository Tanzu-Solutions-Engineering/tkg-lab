#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi
CLUSTER_NAME=$1
IAAS=$(yq r $PARAMS_YAML iaas)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

WAVEFRONT_API_KEY=$(yq r $PARAMS_YAML wavefront.api-key)
WAVEFRONT_URL=$(yq r $PARAMS_YAML wavefront.url)
WAVEFRONT_PREFIX=$(yq r $PARAMS_YAML wavefront.cluster-name-prefix)

kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm upgrade --install wavefront wavefront/wavefront -f $TKG_LAB_SCRIPTS/../wavefront/wf.yml \
  --set wavefront.url=$WAVEFRONT_URL \
  --set wavefront.token=$WAVEFRONT_API_KEY \
  --set clusterName=$WAVEFRONT_PREFIX-$CLUSTER_NAME-$IAAS \
  --namespace wavefront
