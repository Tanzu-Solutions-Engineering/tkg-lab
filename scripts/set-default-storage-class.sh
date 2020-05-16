#!/bin/bash -e

IAAS=$(yq r params.yaml iaas)

if [ "$IAAS" = "aws" ];
then
  kubectl apply -f storage-classes/default-storage-class-aws.yaml
else
  kubectl apply -f storage-classes/default-storage-class-vsphere.yaml
fi
