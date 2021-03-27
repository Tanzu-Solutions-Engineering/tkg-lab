#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)

IAAS=$(yq r $PARAMS_YAML iaas)
VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)
TMC_CLUSTER_GROUP=$(yq r $PARAMS_YAML tmc.cluster-group)


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

EXPECTED_CONTEXT=$MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME 
kubectl config use-context $EXPECTED_CONTEXT --kubeconfig $HOME/.kube-tkg/config

tmc managementcluster register $VMWARE_ID-$MANAGEMENT_CLUSTER_NAME-$IAAS \
  --default-cluster-group $TMC_CLUSTER_GROUP \
  --kubeconfig $HOME/.kube-tkg/config \
  --kubernetes-provider-type 'TKG' 

# the --kubeconfig arg tells tmc to auto-apply the agent bits, but if something goes wrong, 
# they're in the generated directory 
# kubectl apply -f generated/$CLUSTER_NAME/tmc.yaml
echo "$MANAGEMENT_CLUSTER_NAME registered with TMC"