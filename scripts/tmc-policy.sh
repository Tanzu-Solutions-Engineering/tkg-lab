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
IAAS=$(yq e .iaas $PARAMS_YAML)

VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)

tmc cluster iam add-binding $VMWARE_ID-$CLUSTER_NAME-$IAAS \
  --role $ROLE \
  --groups $POLICY_GROUPS \
  --management-cluster-name attached \
  --provisioner-name attached
