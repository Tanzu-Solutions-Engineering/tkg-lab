#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)

mkdir -p generated/$CLUSTER
cp config-templates/aws-mc-config.yaml generated/$CLUSTER/cluster-config.yaml

export REGION=$(yq e .aws.region $PARAMS_YAML)
export SSH_KEY_NAME=tkg-$(yq e .environment-name $PARAMS_YAML)-default
export OIDC_ISSUER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OIDC_CLIENT_ID=$(yq e .okta.tkg-app-client-id $PARAMS_YAML)
export OIDC_CLIENT_SECRET=$(yq e .okta.tkg-app-client-secret $PARAMS_YAML)
export WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)
export AWS_CONTROL_PLANE_MACHINE_TYPE=$(yq e .aws.control-plane-machine-type $PARAMS_YAML)
export AWS_NODE_MACHINE_TYPE=$(yq e .aws.node-machine-type $PARAMS_YAML)
export AWS_VPC_ID=$(terraform -chdir=terraform/aws output -raw vpc_id)
export AWS_PUBLIC_SUBNET_ID=$(terraform -chdir=terraform/aws output -raw public_subnet)
export AWS_PRIVATE_SUBNET_ID=$(terraform -chdir=terraform/aws output -raw private_subnet)

yq e -i '.CLUSTER_NAME = env(CLUSTER)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_REGION = env(REGION)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_SSH_KEY_NAME = env(SSH_KEY_NAME)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_ISSUER_URL = env(OIDC_ISSUER_URL)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_ID = env(OIDC_CLIENT_ID)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.OIDC_IDENTITY_PROVIDER_CLIENT_SECRET = env(OIDC_CLIENT_SECRET)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.CONTROL_PLANE_MACHINE_TYPE = env(AWS_CONTROL_PLANE_MACHINE_TYPE)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.NODE_MACHINE_TYPE = env(AWS_NODE_MACHINE_TYPE)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_VPC_ID = env(AWS_VPC_ID)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_PUBLIC_SUBNET_ID = env(AWS_PUBLIC_SUBNET_ID)' generated/$CLUSTER/cluster-config.yaml
yq e -i '.AWS_PRIVATE_SUBNET_ID = env(AWS_PRIVATE_SUBNET_ID)' generated/$CLUSTER/cluster-config.yaml

tanzu management-cluster create --file=generated/$CLUSTER/cluster-config.yaml -v 6
