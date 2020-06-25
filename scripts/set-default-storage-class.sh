#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/set-env.sh

IAAS=$(yq r $PARAMS_YAML iaas)

if [ "$IAAS" = "aws" ];
then
  kubectl apply -f $DIR/../storage-classes/default-storage-class-aws.yaml
else
  kubectl apply -f $DIR/../storage-classes/default-storage-class-vsphere.yaml
fi
