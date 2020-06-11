#!/bin/bash -e

source ./scripts/set-env.sh

IAAS=$(yq r $PARAMS_YAML iaas)

if [ "$IAAS" = "aws" ];
then
  kubectl apply -f storage-classes/default-storage-class-aws.yaml
else
  kubectl apply -f storage-classes/default-storage-class-vsphere.yaml
fi
