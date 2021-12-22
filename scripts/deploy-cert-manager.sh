#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

VERSION=$(tanzu package available list cert-manager.tanzu.vmware.com -oyaml | yq eval ".[0].version" -)

tanzu package install cert-manager \
    --package-name cert-manager.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp
