#!/bin/bash -e

if [ ! $# -eq 3 ]; then
  echo "Must supply cluster name, role, and groups as args"
  exit 1
fi

CLUSTER_NAME=$1
ROLE=$2
POLICY_GROUPS=$3
IAAS=$(yq r params.yaml iaas)

VMWARE_ID=$(yq r params.yaml vmware-id)

tmc cluster iam add-binding $VMWARE_ID-$CLUSTER_NAME-$IAAS --role $ROLE --groups $POLICY_GROUPS
