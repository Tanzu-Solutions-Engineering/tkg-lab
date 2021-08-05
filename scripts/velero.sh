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
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.1.0,vsphereveleroplugin/velero-plugin-for-vsphere:1.1.0 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
  velero snapshot-location create vsl-vsphere --provider velero.io/vsphere
elif [ -z "$AWS_SESSION_TOKEN" ]; 
then
    echo "Using Credentials File for S3 Access"
    velero install \
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.1.0 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
else
# For cloudgate use case don't need a secret since the IAM role on the cluster node will be used for access.
   echo "Using IAM Profile for S3 Access"
   velero install \
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.1.0 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --no-secret
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
    --volume-snapshot-locations vsl-vsphere
else
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *" 
fi