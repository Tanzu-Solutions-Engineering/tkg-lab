#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)

tmc cluster delete -m attached -p attached $VMWARE_ID-$(yq r $PARAMS_YAML management-cluster.name)-$(yq r $PARAMS_YAML iaas) --force
tmc cluster delete -m attached -p attached $VMWARE_ID-$(yq r $PARAMS_YAML shared-services-cluster.name)-$(yq r $PARAMS_YAML iaas) --force

set +e
if tmc cluster namespace get -p attached -m attached --cluster-name $VMWARE_ID-$(yq r $PARAMS_YAML workload-cluster.name)-$(yq r $PARAMS_YAML iaas) acme-fitness 2>&1 > /dev/null; then 
	tmc cluster namespace delete -m attached -p attached --cluster-name $VMWARE_ID-$(yq r $PARAMS_YAML workload-cluster.name)-$(yq r $PARAMS_YAML iaas) acme-fitness 
fi

if tmc workspace get $(yq r $PARAMS_YAML acme-fitness.tmc-workspace) 2>&1 > /dev/null ; then
	tmc workspace delete $(yq r $PARAMS_YAML acme-fitness.tmc-workspace)
fi
set -e 

tmc cluster delete -m attached -p attached $VMWARE_ID-$(yq r $PARAMS_YAML workload-cluster.name)-$(yq r $PARAMS_YAML iaas) --force

tkg set mc $(yq r $PARAMS_YAML management-cluster.name)
tkg delete cluster $(yq r $PARAMS_YAML workload-cluster.name) --yes
tkg delete cluster $(yq r $PARAMS_YAML shared-services-cluster.name) --yes

#Wait for cluster to be deleted
while tkg get cluster | grep deleting ; [ $? -eq 0 ]; do
	echo "Waiting for clusters to be deleted"
	sleep 5s
done   

tkg delete mc $(yq r $PARAMS_YAML management-cluster.name) --yes
