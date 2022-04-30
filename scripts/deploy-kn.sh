#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME


CRD_INSTALL=$(yq e .kn.crd-install $PARAMS_YAML)
CORE_INSTALL=$(yq e .kn.core-install $PARAMS_YAML)
ISTIO_CONTROLLER_INSTALL=$(yq e .kn.istio-controller $PARAMS_YAML)

bash -c "${CRD_INSTALL}"
bash -c "${CORE_INSTALL}"
bash -c "${ISTIO_CONTROLLER_INSTALL}"
