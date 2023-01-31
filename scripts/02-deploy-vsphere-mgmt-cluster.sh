#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

#####################
# get variables
#####################

# Get cluster name and prepare cluster-config file
export CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export CLUSTER_CONFIG="generated/$CLUSTER_NAME/cluster-config.yaml"

export CONTROLPLANE_ENDPOINT=$(yq e .management-cluster.controlplane-endpoint $PARAMS_YAML)
export OIDC_IDENTITY_PROVIDER_ISSUER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OIDC_IDENTITY_PROVIDER_CLIENT_ID=$(yq e .okta.tkg-app-client-id $PARAMS_YAML)
export OIDC_IDENTITY_PROVIDER_CLIENT_SECRET=$(yq e .okta.tkg-app-client-secret $PARAMS_YAML)
export WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)
export AVI_CA_DATA_B64=$(yq e .avi.avi-ca-data $PARAMS_YAML)
export AVI_CLOUD_NAME=$(yq e .avi.avi-cloud-name $PARAMS_YAML)
export AVI_CONTROLLER=$(yq e .avi.avi-controller $PARAMS_YAML)
export AVI_DATA_NETWORK=$(yq e .avi.avi-data-network $PARAMS_YAML)
export AVI_DATA_NETWORK_CIDR=$(yq e .avi.avi-data-network-cidr $PARAMS_YAML)
export AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME=$(yq e .avi.avi-management-cluster-vip-network $PARAMS_YAML)
export AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR=$(yq e .avi.avi-management-cluster-vip-network-cidr $PARAMS_YAML)
export AVI_LABELS=$(yq e .avi.avi-labels $PARAMS_YAML)
export AVI_PASSWORD=$(yq e .avi.avi-password $PARAMS_YAML)
export AVI_SERVICE_ENGINE_GROUP=$(yq e .avi.avi-service-engine-group $PARAMS_YAML)
export AVI_USERNAME=$(yq e .avi.avi-username $PARAMS_YAML)
NODE_OS=$(yq e .vsphere.node-os $PARAMS_YAML)
if [ "$NODE_OS" = "photon" ];
then
  export NODE_OS="photon"
  export NODE_VERSION="3"
else
  export NODE_OS="ubuntu"
  export NODE_VERSION="20.04"
fi

###################################
# set variables into cluster config
###################################
yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' "$CLUSTER_CONFIG"
yq e -i '.VSPHERE_CONTROL_PLANE_ENDPOINT = env(CONTROLPLANE_ENDPOINT)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_ISSUER_URL = env(OIDC_IDENTITY_PROVIDER_ISSUER_URL)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_ID = env(OIDC_IDENTITY_PROVIDER_CLIENT_ID)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_SECRET = env(OIDC_IDENTITY_PROVIDER_CLIENT_SECRET)' "$CLUSTER_CONFIG"
yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' "$CLUSTER_CONFIG"
yq e -i '.AVI_CA_DATA_B64 = strenv(AVI_CA_DATA_B64)' "$CLUSTER_CONFIG"
yq e -i '.AVI_CLOUD_NAME = env(AVI_CLOUD_NAME)' "$CLUSTER_CONFIG"
yq e -i '.AVI_CONTROLLER = env(AVI_CONTROLLER)' "$CLUSTER_CONFIG"
yq e -i '.AVI_DATA_NETWORK = env(AVI_DATA_NETWORK)' "$CLUSTER_CONFIG"
yq e -i '.AVI_DATA_NETWORK_CIDR = env(AVI_DATA_NETWORK_CIDR)' "$CLUSTER_CONFIG"
yq e -i '.AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME = env(AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME)' "$CLUSTER_CONFIG"
yq e -i '.AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR = env(AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR)' "$CLUSTER_CONFIG"
yq e -i '.AVI_LABELS = strenv(AVI_LABELS)' "$CLUSTER_CONFIG"
yq e -i '.AVI_PASSWORD = strenv(AVI_PASSWORD)' "$CLUSTER_CONFIG"
yq e -i '.AVI_SERVICE_ENGINE_GROUP = env(AVI_SERVICE_ENGINE_GROUP)' "$CLUSTER_CONFIG"
yq e -i '.AVI_USERNAME = env(AVI_USERNAME)' "$CLUSTER_CONFIG"
yq e -i '.OS_NAME = env(NODE_OS)' "$CLUSTER_CONFIG"
yq e -i '.OS_VERSION = env(NODE_VERSION)' "$CLUSTER_CONFIG"

tanzu management-cluster create --file=$CLUSTER_CONFIG -v 6 -y
