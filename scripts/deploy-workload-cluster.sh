#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and worker replicas as args"
  exit 1
fi
CLUSTER_NAME=$1
WORKER_REPLICAS=$2

IAAS=$(yq r $PARAMS_YAML iaas)
DEX_CN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)

INFRA_COMPONENTS_PATH=$(yq read ~/.tkg/config.yaml "providers[name==vsphere].url")
OIDC_PLAN_PATH=$(sed s/infrastructure-components/cluster-template-oidc/g <<< $INFRA_COMPONENTS_PATH)

if [ $IAAS = 'aws' ];
then
  INFRA_COMPONENTS_PATH=$(yq read ~/.tkg/config.yaml "providers[name==aws].url")
  OIDC_PLAN_PATH=$(sed s/infrastructure-components/cluster-template-oidc/g <<< $INFRA_COMPONENTS_PATH)
  cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml $OIDC_PLAN_PATH
else
  INFRA_COMPONENTS_PATH=$(yq read ~/.tkg/config.yaml "providers[name==vsphere].url")
  OIDC_PLAN_PATH=$(sed s/infrastructure-components/cluster-template-oidc/g <<< $INFRA_COMPONENTS_PATH)
  cp tkg-extensions/authentication/dex/vsphere/cluster-template-oidc.yaml $OIDC_PLAN_PATH
fi

export OIDC_ISSUER_URL=https://$DEX_CN
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

tkg create cluster $CLUSTER_NAME --plan=oidc -w $WORKER_REPLICAS -v 6
tkg get credentials $CLUSTER_NAME

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

./scripts/set-default-storage-class.sh
