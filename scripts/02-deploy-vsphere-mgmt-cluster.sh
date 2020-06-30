#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)

tkg init --infrastructure=vsphere --name=$MANAGEMENT_CLUSTER_NAME --plan=dev -v 6
