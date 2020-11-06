#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

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

if [ "$IAAS" = "aws" ];
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


if [ "$IAAS" = "aws" ];
then
  
  MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
  kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

  export AWS_VPC_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.vpc.id}")
  export AWS_PUBLIC_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==true)].id}")
  export AWS_PRIVATE_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==false)].id}")

  mkdir -p generated/$CLUSTER_NAME

  tkg config cluster $CLUSTER_NAME \
    --plan=oidc \
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
  tkg create cluster $CLUSTER_NAME --plan=oidc -w $WORKER_REPLICAS -v 6
fi

tkg get credentials $CLUSTER_NAME

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
