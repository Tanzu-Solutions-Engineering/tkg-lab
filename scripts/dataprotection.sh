#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name"
  exit 1
fi

echo "Enabling TMC data protection (powered by Velero)..."

CLUSTER_NAME=$1
BACKUP_LOCATION=$(yq e .tmc.data-protection-backup-location-name $PARAMS_YAML)

IAAS=$(yq e .iaas $PARAMS_YAML)
VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)

tmc cluster dataprotection create --management-cluster-name attached \
  --provisioner-name attached \
  --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} \
  --backup-location-names ${BACKUP_LOCATION}

# Wait for it to be ready
while [[ $(tmc cluster dataprotection get -m attached -p attached --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} | yq e -o=json | jq .status.phase -r) != "READY" ]] ; do
  echo Velero is not yet ready
  sleep 5
done

# Setup the backup schedule
tmc cluster dataprotection schedule create --management-cluster-name attached \
  --provisioner-name attached \
  --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} \
  --backup-location-name ${BACKUP_LOCATION} \
  --name daily \
  --rate "0 7 * * *"
