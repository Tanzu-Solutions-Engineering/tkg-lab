#!/bin/bash -e

VMWARE_ID=$(yq r params.yaml vmware-id)

tmc cluster delete $VMWARE_ID-$(yq r params.yaml management-cluster.name) --force
tmc cluster delete $VMWARE_ID-$(yq r params.yaml shared-services-cluster.name) --force

tmc workspace delete $(yq r params.yaml acme-fitness.tmc-workspace) --force
tmc cluster delete $VMWARE_ID-$(yq r params.yaml workload-cluster.name) --force

tkg set mc $(yq r params.yaml management-cluster.name) --yes
tkg delete cluster $(yq r params.yaml workload-cluster.name) --yes
tkg delete cluster $(yq r params.yaml shared-services-cluster.name) --yes
tkg delete mc --yes