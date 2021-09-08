#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as arg"
  exit 1
fi

echo "Beginning Velero install..."

CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

VELERO_BUCKET=$(yq e .velero.bucket $PARAMS_YAML)
VELERO_REGION=$(yq e .velero.region $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" = "vsphere" ];
then
  velero install \
      --image=projects.registry.vmware.com/tkg/velero/velero:v1.6.2_vmware.1 \
      --provider aws \
      --plugins=projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.2.1_vmware.1,projects.registry.vmware.com/tkg/velero/velero-plugin-for-vsphere:v1.1.1_vmware.1 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
else
  velero install \
      --image=projects.registry.vmware.com/tkg/velero/velero:v1.6.2_vmware.1 \
      --provider aws \
      --plugins projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.2.1_vmware.1 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
fi

# Wait for it to be ready
while kubectl get po -n velero | grep Running ; [ $? -ne 0 ]; do
	echo Velero is not yet ready
	sleep 5s
done

# Setup the backup schedule
if [ "$IAAS" = "vsphere" ];
then
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *" \
    --volume-snapshot-locations default
else
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *"
fi
