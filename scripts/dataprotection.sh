#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and backup location as arg"
  exit 1
fi

echo "Enabling TMC data protection (powered by Velero)..."

CLUSTER_NAME=$1
BACKUP_LOCATION=$2

IAAS=$(yq r $PARAMS_YAML iaas)
VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)

tmc cluster dataprotection create --management-cluster-name attached \
  --provisioner-name attached \
  --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} \
  --backup-location-names ${BACKUP_LOCATION} 

# Wait for it to be ready
while [[ $(tmc cluster dataprotection get -m attached -p attached --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} | yq r - status.phase ) != "READY" ]] ; do
  echo Velero is not yet ready
  sleep 5s
done

# Setup the backup schedule
tmc cluster dataprotection schedule create --management-cluster-name attached \
  --provisioner-name attached \
  --cluster-name ${VMWARE_ID}-${CLUSTER_NAME}-${IAAS} \
  --backup-location-name ${BACKUP_LOCATION} \
  --name daily \
  --rate "0 7 * * *"
