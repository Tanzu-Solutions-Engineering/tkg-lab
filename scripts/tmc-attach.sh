#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq r $PARAMS_YAML iaas)
VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)
TMC_CLUSTER_GROUP=$(yq r $PARAMS_YAML tmc.cluster-group)

mkdir -p generated/$CLUSTER_NAME

if tmc system context current | grep -q IDToken; then
  echo "Currently logged into TMC."
else
  echo "Please login to tmc before you continue."
  exit 1
fi

if tmc clustergroup list | grep -q $TMC_CLUSTER_GROUP; then
  echo "Cluster group $TMC_CLUSTER_GROUP found."
else
  echo "Cluster group $TMC_CLUSTER_GROUP not found.  Automattically creating it."
  tmc clustergroup create -n $TMC_CLUSTER_GROUP
fi

tmc cluster attach \
  --name $VMWARE_ID-$CLUSTER_NAME-$IAAS \
  --labels origin=$VMWARE_ID \
  --labels iaas=$IAAS \
  --cluster-group $TMC_CLUSTER_GROUP \
  --output generated/$CLUSTER_NAME/tmc.yaml
kubectl apply -f generated/$CLUSTER_NAME/tmc.yaml
echo "$CLUSTER_NAME registered with TMC"
