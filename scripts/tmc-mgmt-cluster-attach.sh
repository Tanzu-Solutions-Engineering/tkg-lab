#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export IAAS=$(yq e .iaas $PARAMS_YAML)
export VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
export TMC_CLUSTER_GROUP=$(yq e .tmc.cluster-group $PARAMS_YAML)
export TMC_API_TOKEN=$(yq e .tmc.api-token $PARAMS_YAML)


tmc login --no-configure --name $(yq e .tmc.context-name $PARAMS_YAML)

if tmc clustergroup list | grep -q $TMC_CLUSTER_GROUP; then
  echo "Cluster group $TMC_CLUSTER_GROUP found."
else
  echo "Cluster group $TMC_CLUSTER_GROUP not found.  Automattically creating it."
  tmc clustergroup create -n $TMC_CLUSTER_GROUP
fi

EXPECTED_CONTEXT=$MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME 
kubectl config use-context $EXPECTED_CONTEXT --kubeconfig $HOME/.kube-tkg/config

tmc managementcluster register $MANAGEMENT_CLUSTER_NAME \
  --default-cluster-group $TMC_CLUSTER_GROUP \
  --kubeconfig $HOME/.kube-tkg/config \
  --kubernetes-provider-type 'TKG' 

# the --kubeconfig arg tells tmc to auto-apply the agent bits, but if something goes wrong, 
# they're in the generated directory 
# kubectl apply -f generated/$CLUSTER_NAME/tmc.yaml
echo "$MANAGEMENT_CLUSTER_NAME registered with TMC"