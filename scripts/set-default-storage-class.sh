#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq r $PARAMS_YAML iaas)

if [ "$IAAS" = "aws" ];
then
  kubectl apply -f $TKG_LAB_SCRIPTS/../storage-classes/default-storage-class-aws.yaml
else
  kubectl apply -f $TKG_LAB_SCRIPTS/../storage-classes/default-storage-class-vsphere.yaml
fi
