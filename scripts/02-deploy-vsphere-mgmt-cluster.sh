#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
export CONTROLPLANE_ENDPOINT_IP=$(yq r $PARAMS_YAML management-cluster.controlplane-endpoint-ip)

tkg init --infrastructure=vsphere --name=$MANAGEMENT_CLUSTER_NAME --vsphere-controlplane-endpoint-ip=$CONTROLPLANE_ENDPOINT_IP --ceip-participation=false --plan=dev -v 6 --deploy-tkg-on-vSphere7
