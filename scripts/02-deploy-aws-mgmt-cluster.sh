#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ "$TKG_CONFIG" = "" ]; then
  TKG_CONFIG=~/.tkg/config.yaml
fi

export MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

mkdir -p generated/$MANAGEMENT_CLUSTER_NAME
cp config-templates/aws-cluster-config.yaml generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml

export REGION=$(yq e .aws.region $PARAMS_YAML)
export AWS_SSH_KEY_NAME=tkg-$(yq e .environment-name $PARAMS_YAML)-default
export OIDC_IDENTITY_PROVIDER_ISSUER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OIDC_IDENTITY_PROVIDER_CLIENT_ID=$(yq e .okta.dex-app-client-id $PARAMS_YAML)
export OIDC_IDENTITY_PROVIDER_CLIENT_SECRET=$(yq e .okta.dex-app-client-secret $PARAMS_YAML)
export WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)

yq e -i '.CLUSTER_NAME = env(MANAGEMENT_CLUSTER_NAME)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.AWS_REGION = env(REGION)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.AWS_SSH_KEY_NAME = env(AWS_SSH_KEY_NAME)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_ISSUER_URL = env(OIDC_IDENTITY_PROVIDER_ISSUER_URL)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_ID = env(OIDC_IDENTITY_PROVIDER_CLIENT_ID)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_SECRET = env(OIDC_IDENTITY_PROVIDER_CLIENT_SECRET)' generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml
yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER_NAME/cluster-config.yaml

tanzu management-cluster create --file=generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml -v 6
