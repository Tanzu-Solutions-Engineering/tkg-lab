#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi
CLUSTER_NAME=$1
IAAS=$(yq e .iaas $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

WAVEFRONT_API_KEY=$(yq e .wavefront.api-key $PARAMS_YAML)
WAVEFRONT_URL=$(yq e .wavefront.url $PARAMS_YAML)
WAVEFRONT_PREFIX=$(yq e .wavefront.cluster-name-prefix $PARAMS_YAML)

kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm upgrade --install wavefront wavefront/wavefront \
  --set wavefront.url=$WAVEFRONT_URL \
  --set wavefront.token=$WAVEFRONT_API_KEY \
  --set clusterName=$WAVEFRONT_PREFIX-$CLUSTER_NAME-$IAAS \
  --set events.enabled=true \
  --set kubeStateMetrics.enabled=true \
  --namespace wavefront
