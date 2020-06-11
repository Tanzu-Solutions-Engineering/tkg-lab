#!/bin/bash -e

source ./scripts/set-env.sh

echo "Beginning Velero install..."

VELERO_BUCKET=$(yq r $PARAMS_YAML velero.bucket)
VELERO_REGION=$(yq r $PARAMS_YAML velero.region)

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as arg"
  exit 1
fi
CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.1 \
    --bucket $VELERO_BUCKET \
    --backup-location-config region=$VELERO_REGION \
    --snapshot-location-config region=$VELERO_REGION \
    --secret-file keys/credentials-velero

#Wait for it to be ready
while kubectl get po -n velero | grep Running ; [ $? -ne 0 ]; do
	echo Velero is not yet ready
	sleep 5s
done

velero schedule create daily-$CLUSTER_NAME-cluster-backup --schedule "0 7 * * *"
