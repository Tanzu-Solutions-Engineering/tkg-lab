#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
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

yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_CONTROL_PLANE_ENDPOINT = env(CONTROLPLANE_ENDPOINT)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_ISSUER_URL = env(OIDC_IDENTITY_PROVIDER_ISSUER_URL)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_ID = env(OIDC_IDENTITY_PROVIDER_CLIENT_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_SECRET = env(OIDC_IDENTITY_PROVIDER_CLIENT_SECRET)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_CA_DATA_B64 = strenv(AVI_CA_DATA_B64)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_CLOUD_NAME = env(AVI_CLOUD_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_CONTROLLER = env(AVI_CONTROLLER)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_DATA_NETWORK = env(AVI_DATA_NETWORK)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_DATA_NETWORK_CIDR = env(AVI_DATA_NETWORK_CIDR)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME = env(AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR = env(AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_LABELS = strenv(AVI_LABELS)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_PASSWORD = strenv(AVI_PASSWORD)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_SERVICE_ENGINE_GROUP = env(AVI_SERVICE_ENGINE_GROUP)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.AVI_USERNAME = env(AVI_USERNAME)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.OS_NAME = env(NODE_OS)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.OS_VERSION = env(NODE_VERSION)' generated/$CLUSTER_NAME/cluster-config.yaml

tanzu management-cluster create --file=generated/$CLUSTER_NAME/cluster-config.yaml -v 6 -y
