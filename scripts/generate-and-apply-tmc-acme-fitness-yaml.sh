#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
 echo "Must supply cluster name as args"
 exit 1
fi
CLUSTER_NAME=$1

IAAS=$(yq e .iaas $PARAMS_YAML)

export TMC_ACME_FITNESS_WORKSPACE_NAME=$(yq e .acme-fitness.tmc-workspace $PARAMS_YAML)
export VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
export TMC_CLUSTER_NAME=$VMWARE_ID-$CLUSTER_NAME-$IAAS

mkdir -p generated/$CLUSTER_NAME/tmc
cp -r tmc/config/* generated/$CLUSTER_NAME/tmc/

# acme-fitness-dev.yaml
yq e -i ".fullName.name = env(TMC_ACME_FITNESS_WORKSPACE_NAME)" generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml
yq e -i ".meta.labels.origin = env(VMWARE_ID)" generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml

# tkg-wlc-acme-fitness.yaml
yq e -i ".fullName.clusterName = env(TMC_CLUSTER_NAME)" generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml
yq e -i ".meta.labels.origin = env(VMWARE_ID)"  generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml
yq e -i ".spec.workspaceName = env(TMC_ACME_FITNESS_WORKSPACE_NAME)" generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml

if tmc workspace list | grep -q $TMC_ACME_FITNESS_WORKSPACE_NAME; then
    tmc workspace delete $TMC_ACME_FITNESS_WORKSPACE_NAME
fi
tmc workspace create -f generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml
tmc workspace iam add-binding $TMC_ACME_FITNESS_WORKSPACE_NAME --role workspace.edit --groups acme-fitness-devs
tmc cluster namespace create -f generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml
