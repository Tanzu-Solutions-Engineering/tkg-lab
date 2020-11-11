#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq r $PARAMS_YAML iaas)
if [ "$IAAS" = "aws" ];
then
  if [ ! $# -eq 2 ]; then
    echo "Must supply cluster name and worker replicas as args"
    exit 1
  fi
else
  if [ ! $# -eq 3 ]; then
    echo "Must supply cluster name and worker replicas and control plane ip as args"
    exit 1
  fi
  VSPHERE_CONTROLPLANE_ENDPOINT_IP=$3
fi

CLUSTER_NAME=$1
WORKER_REPLICAS=$2

DEX_CN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)

export OIDC_ISSUER_URL=https://$DEX_CN
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export OIDC_DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

if [ "$IAAS" = "aws" ];
then
  
  MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
  kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

  export AWS_VPC_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.vpc.id}")
  export AWS_PUBLIC_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==true)].id}")
  export AWS_PRIVATE_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==false)].id}")

  mkdir -p generated/$CLUSTER_NAME

  tkg config cluster $CLUSTER_NAME \
    --enable-cluster-options oidc \
    --plan=dev \
    -w $WORKER_REPLICAS \
    | ytt \
      --ignore-unknown-comments \
      -f capi-overrides/disable-aws-bastion.yaml \
      -f - \
      > generated/$CLUSTER_NAME/cluster-manifest.yaml
  tkg create cluster $CLUSTER_NAME -v6 --manifest generated/$CLUSTER_NAME/cluster-manifest.yaml

  # The following additional step is required when deploying workload clusters to the same VPC as the management cluster in order for LoadBalancers to be created properly
  aws ec2 create-tags --resources $AWS_PUBLIC_SUBNET_ID --tags Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared

else
  tkg create cluster $CLUSTER_NAME \
    --enable-cluster-options oidc \
    --plan dev \
    --vsphere-controlplane-endpoint-ip $VSPHERE_CONTROLPLANE_ENDPOINT_IP \
    -w $WORKER_REPLICAS -v 6
fi

tkg get credentials $CLUSTER_NAME

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
