#!/bin/bash -e

source ./scripts/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)

tkg init --infrastructure=vsphere --name=$MANAGEMENT_CLUSTER_NAME --plan=dev -v 6
