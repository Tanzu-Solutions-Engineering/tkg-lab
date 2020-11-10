#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
 echo "Must supply cluster name as args"
 exit 1
fi
CLUSTER_NAME=$1

TMC_ACME_FITNESS_WORKSPACE_NAME=$(yq r $PARAMS_YAML acme-fitness.tmc-workspace)
VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)
IAAS=$(yq r $PARAMS_YAML iaas)

mkdir -p generated/$CLUSTER_NAME/tmc
cp -r tmc/config/* generated/$CLUSTER_NAME/tmc/

# acme-fitness-dev.yaml
yq write -d0 generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml -i "fullName.name" $TMC_ACME_FITNESS_WORKSPACE_NAME
yq write -d0 generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml -i "meta.labels.origin" $VMWARE_ID

# tkg-wlc-acme-fitness.yaml
yq write -d0 generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml -i "fullName.clusterName" $VMWARE_ID-$CLUSTER_NAME-$IAAS
yq write -d0 generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml -i "meta.labels.origin" $VMWARE_ID
yq write -d0 generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml -i "spec.workspaceName" $TMC_ACME_FITNESS_WORKSPACE_NAME

tmc workspace create -f generated/$CLUSTER_NAME/tmc/workspace/acme-fitness-dev.yaml
tmc workspace iam add-binding $TMC_ACME_FITNESS_WORKSPACE_NAME --role workspace.edit --groups acme-fitness-devs
tmc cluster namespace create -f generated/$CLUSTER_NAME/tmc/namespace/tkg-wlc-acme-fitness.yaml
