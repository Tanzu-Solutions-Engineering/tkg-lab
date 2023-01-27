#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

#####################
# get variables
#####################

# Get cluster name and prepare cluster-config file
export CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export CLUSTER_CONFIG="generated/$CLUSTER_NAME/cluster-config.yaml"

export AZURE_CLIENT_ID=$(yq e .azure.client-id $PARAMS_YAML)
export AZURE_CLIENT_SECRET=$(yq e .azure.client-secret $PARAMS_YAML)
export AZURE_CONTROL_PLANE_MACHINE_TYPE=$(yq e .azure.control-plane-machine-type $PARAMS_YAML)
export AZURE_LOCATION=$(yq e .azure.location $PARAMS_YAML)
export AZURE_NODE_MACHINE_TYPE=$(yq e .azure.node-machine-type $PARAMS_YAML)
export AZURE_SUBSCRIPTION_ID=$(yq e .azure.subscription-id $PARAMS_YAML)
export AZURE_TENANT_ID=$(yq e .azure.tenant-id $PARAMS_YAML)
export OIDC_ISSUER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OIDC_CLIENT_ID=$(yq e .okta.tkg-app-client-id $PARAMS_YAML)
export OIDC_CLIENT_SECRET=$(yq e .okta.tkg-app-client-secret $PARAMS_YAML)
export WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)

###################################
# set variables into cluster config
###################################
yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_CLIENT_ID = env(AZURE_CLIENT_ID)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_CLIENT_SECRET = env(AZURE_CLIENT_SECRET)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_CONTROL_PLANE_MACHINE_TYPE = env(AZURE_CONTROL_PLANE_MACHINE_TYPE)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_LOCATION = env(AZURE_LOCATION)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_NODE_MACHINE_TYPE = env(AZURE_NODE_MACHINE_TYPE)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_SUBSCRIPTION_ID = env(AZURE_SUBSCRIPTION_ID)' "$CLUSTER_CONFIG"
yq e -i '.AZURE_TENANT_ID = env(AZURE_TENANT_ID)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_ISSUER_URL = env(OIDC_ISSUER_URL)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_ID = env(OIDC_CLIENT_ID)' "$CLUSTER_CONFIG"
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_SECRET = env(OIDC_CLIENT_SECRET)' "$CLUSTER_CONFIG"
yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' "$CLUSTER_CONFIG"

# create the cluster
tanzu management-cluster create --file=$CLUSTER_CONFIG -v 6
