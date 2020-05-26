#!/bin/bash -e

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq r params.yaml iaas)
VMWARE_ID=$(yq r params.yaml vmware-id)
TMC_CLUSTER_GROUP=$(yq r params.yaml tmc.cluster-group)

mkdir -p generated/$CLUSTER_NAME

tmc cluster attach \
  --name $VMWARE_ID-$CLUSTER_NAME \
  --labels origin=$VMWARE_ID \
  --labels iaas=$IAAS \
  --group $TMC_CLUSTER_GROUP \
  --output generated/$CLUSTER_NAME/tmc.yaml
kubectl apply -f generated/$CLUSTER_NAME/tmc.yaml
echo "$CLUSTER_NAME registered with TMC"