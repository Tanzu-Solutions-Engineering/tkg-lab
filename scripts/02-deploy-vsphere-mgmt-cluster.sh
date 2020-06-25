#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)

tkg init --infrastructure=vsphere --name=$MANAGEMENT_CLUSTER_NAME --plan=dev -v 6
