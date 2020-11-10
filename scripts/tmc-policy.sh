#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 3 ]; then
  echo "Must supply cluster name, role, and groups as args"
  exit 1
fi

CLUSTER_NAME=$1
ROLE=$2
POLICY_GROUPS=$3
IAAS=$(yq r $PARAMS_YAML iaas)

VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)

tmc cluster iam add-binding $VMWARE_ID-$CLUSTER_NAME-$IAAS \
  --management-cluster-name attached \
  --provisioner-name attached \
  --role $ROLE \
  --groups $POLICY_GROUPS
