#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
MC_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

tmc cluster delete $VMWARE_ID-$(yq e .shared-services-cluster.name $PARAMS_YAML)-$(yq e .iaas $PARAMS_YAML) -m attached -p attached --force
tmc cluster delete $VMWARE_ID-$(yq e .workload-cluster.name $PARAMS_YAML)-$(yq e .iaas $PARAMS_YAML) -m attached -p attached  --force

tanzu login --server $MC_CLUSTER_NAME
tanzu cluster delete $(yq e .workload-cluster.name $PARAMS_YAML) --yes
tanzu cluster delete $(yq e .shared-services-cluster.name $PARAMS_YAML) --yes

#Wait for clusters to be deleted
while tanzu cluster list | grep deleting ; [ $? -eq 0 ]; do
	echo "Waiting for clusters to be deleted"
	sleep 5s
done   

# HACK: Kubeconfig should not be required, OLYMP-26147 has been created address this.  Set current context to managment cluster
kubectl config use-context $MC_CLUSTER_NAME-admin@$MC_CLUSTER_NAME
tmc managementcluster deregister $MC_CLUSTER_NAME --force --kubeconfig ~/.kube/config

tanzu management-cluster delete -y
