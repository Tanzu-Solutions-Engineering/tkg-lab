#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)

tmc cluster delete $VMWARE_ID-$(yq e .shared-services-cluster.name $PARAMS_YAML)-$(yq e .iaas $PARAMS_YAML) -m attached -p attached --force
tmc cluster delete $VMWARE_ID-$(yq e .workload-cluster.name $PARAMS_YAML)-$(yq e .iaas $PARAMS_YAML) -m attached -p attached  --force

tanzu login --server $(yq e .management-cluster.name $PARAMS_YAML)
tanzu cluster delete $(yq e .workload-cluster.name $PARAMS_YAML) --yes
tanzu cluster delete $(yq e .shared-services-cluster.name $PARAMS_YAML) --yes

#Wait for clusters to be deleted
while tanzu cluster list | grep deleting ; [ $? -eq 0 ]; do
	echo "Waiting for clusters to be deleted"
	sleep 5s
done   

tmc managementcluster deregister $(yq e .management-cluster.name $PARAMS_YAML) --force

tanzu management-cluster delete -y