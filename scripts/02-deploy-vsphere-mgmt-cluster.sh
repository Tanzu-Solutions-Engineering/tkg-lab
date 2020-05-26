#!/bin/bash -e

export MANAGEMENT_CLUSTER_NAME=$(yq r params.yaml management-cluster.name)

tkg init --infrastructure=vsphere --name=$MANAGEMENT_CLUSTER_NAME --plan=dev -v 6
