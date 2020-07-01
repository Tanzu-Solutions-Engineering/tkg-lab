#!/bin/bash -e

source ./scripts/set-env.sh

VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)

tmc cluster delete $VMWARE_ID-$(yq r $PARAMS_YAML management-cluster.name) --force
tmc cluster delete $VMWARE_ID-$(yq r $PARAMS_YAML shared-services-cluster.name) --force

tmc cluster namespace delete acme-fitness $VMWARE_ID-$(yq r $PARAMS_YAML workload-cluster.name)
tmc workspace delete $(yq r $PARAMS_YAML acme-fitness.tmc-workspace)
tmc cluster delete $VMWARE_ID-$(yq r $PARAMS_YAML workload-cluster.name) --force

tkg set mc $(yq r $PARAMS_YAML management-cluster.name)
tkg delete cluster $(yq r $PARAMS_YAML workload-cluster.name) --yes
tkg delete cluster $(yq r $PARAMS_YAML shared-services-cluster.name) --yes

#Wait for cert to be ready
while tkg get cluster | grep deleting ; [ $? -eq 0 ]; do
	echo "Waiting for clusters to be deleted"
	sleep 5s
done   

tkg delete mc $(yq r $PARAMS_YAML management-cluster.name) --yes