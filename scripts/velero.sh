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
  # this condition uses the velero-plugin-for-vsphere which is special for 
  # Note: will not work with CloudGate AWS permissions
  velero install \
      --image=projects.registry.vmware.com/tkg/velero/velero:v1.6.2_vmware.1 \
      --provider aws \
      --plugins=projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.2.1_vmware.1,projects.registry.vmware.com/tkg/velero/velero-plugin-for-vsphere:v1.1.1_vmware.1 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
elif [ -z "$AWS_SESSION_TOKEN" ];
  # this condition is for AWS without CloudGate or for Azure (yes, azure still uses the plugin for aws)
  # note for Azure users, it will only work if you have non-CloudGate AWS credentials for S3
  velero install \
      --image=projects.registry.vmware.com/tkg/velero/velero:v1.6.2_vmware.1 \
      --provider aws \
      --plugins projects.registry.vmware.com/tkg/velero/velero-plugin-for-aws:v1.2.1_vmware.1 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
else
  # this condition is for AWS with CloudGate use case don't need a secret since the IAM role on the cluster node will be used for access.

  # For Cloudgate we will must add the permission to the policy the nodes run with and also indicate --no-secret flag in install command
  aws iam attach-role-policy --role-name nodes.tkg.cloud.vmware.com --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

  echo "Using IAM Profile for S3 Access"
  velero install \
      --image=projects.registry.vmware.com/tkg/velero/velero:v1.6.2_vmware.1 \
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
    --volume-snapshot-locations default
else
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *"
fi
