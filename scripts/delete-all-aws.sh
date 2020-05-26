#!/bin/bash -e

VMWARE_ID=$(yq r params.yaml vmware-id)

tmc cluster delete $VMWARE_ID-$(yq r params.yaml management-cluster.name) --force
tmc cluster delete $VMWARE_ID-$(yq r params.yaml shared-services-cluster.name) --force

tmc cluster namespace delete acme-fitness $VMWARE_ID-$(yq r params.yaml workload-cluster.name)
tmc workspace delete $(yq r params.yaml acme-fitness.tmc-workspace)
tmc cluster delete $VMWARE_ID-$(yq r params.yaml workload-cluster.name) --force

tkg set mc $(yq r params.yaml management-cluster.name)
tkg delete cluster $(yq r params.yaml workload-cluster.name) --yes
tkg delete cluster $(yq r params.yaml shared-services-cluster.name) --yes

#Wait for cert to be ready
while tkg get cluster | grep Deleting ; [ $? -eq 0 ]; do
	echo "Waiting for clusters to be deleted"
	sleep 5s
done   

tkg delete mc --yes