#!/bin/bash -e

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and worker replicas as args"
  exit 1
fi
CLUSTER_NAME=$1
WORKER_REPLICAS=$2

IAAS=$(yq r params.yaml iaas)
DEX_CN=$(yq r params.yaml management-cluster.dex-fqdn)

if [ $IAAS = 'aws' ];
then
  # Note  Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-aws/v0.5.2/
  cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-aws/v0.5.2/
else
  # Note  Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-vsphere/v0.6.3/
  cp tkg-extensions/authentication/dex/vsphere/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-vsphere/v0.6.3/
fi

export OIDC_ISSUER_URL=https://$DEX_CN
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

tkg create cluster $CLUSTER_NAME --plan=oidc -w $WORKER_REPLICAS -v 6

./scripts/set-default-storage-class.sh
