#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq e .iaas $PARAMS_YAML)
VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
TMC_CLUSTER_GROUP=$(yq e .tmc.cluster-group $PARAMS_YAML)

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
  echo "Cluster group $TMC_CLUSTER_GROUP not found.  Automatically creating it."
  tmc clustergroup create -n $TMC_CLUSTER_GROUP
fi

TMC_CLUSTER_NAME=$VMWARE_ID-$CLUSTER_NAME-$IAAS
ATTACH=true

if tmc cluster list | grep -q $TMC_CLUSTER_NAME; then
  if [ "$(tmc cluster get $TMC_CLUSTER_NAME -p attached -m attached | yq e '.status.health' -)" == "HEALTHY" ]; then
    echo "Cluster is already attached and healthy."
    ATTACH=false
  else
    echo "Cluster is already attached and unhealthy, likely an old reference.  Will detach and re-attach."
    echo "Detaching cluster."
    tmc cluster delete $TMC_CLUSTER_NAME -m attached -p attached --force

    while tmc cluster list | grep -q $TMC_CLUSTER_NAME; do
      echo Waiting for cluster to finish detaching.
      sleep 5
    done

  fi
fi

if $ATTACH; then
  echo "Attaching cluster now."
  tmc cluster attach \
    --name $TMC_CLUSTER_NAME \
    --labels origin=$VMWARE_ID \
    --labels iaas=$IAAS \
    --cluster-group $TMC_CLUSTER_GROUP \
    --output generated/$CLUSTER_NAME/tmc.yaml
fi

kubectl apply -f generated/$CLUSTER_NAME/tmc.yaml
echo "$CLUSTER_NAME registered with TMC"
