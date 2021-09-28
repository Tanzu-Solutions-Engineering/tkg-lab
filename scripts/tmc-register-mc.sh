#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq e .iaas $PARAMS_YAML)
TMC_CLUSTER_GROUP=$(yq e .tmc.cluster-group $PARAMS_YAML)

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

if [ "$IAAS" == "aws" ];
then
  echo "Warning! Please note, although you management cluster will be registered, TMC features associated to the management cluster are only supported for TKG on vSphere and Azure at this time."
fi

mkdir -p generated/$CLUSTER_NAME/tmc

tmc managementcluster register $CLUSTER_NAME \
  --default-cluster-group $TMC_CLUSTER_GROUP \
  --kubernetes-provider-type TKG

TMC_REGISTRATION_URL=$(tmc managementcluster get $CLUSTER_NAME | yq e .status.registrationUrl -)

tanzu management-cluster register --tmc-registration-url $TMC_REGISTRATION_URL

echo "$CLUSTER_NAME registered as management-cluster with TMC"
