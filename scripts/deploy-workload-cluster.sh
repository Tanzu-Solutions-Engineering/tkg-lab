#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq e .iaas $PARAMS_YAML)
VSPHERE_CONTROLPLANE_ENDPOINT=$3
KUBERNETES_VERSION=$4

export CLUSTER_NAME=$1
WORKER_REPLICAS=$2

KUBERNETES_VERSION_FLAG_AND_VALUE=""
if [ ! "$KUBERNETES_VERSION" = "null" ]; then
  KUBERNETES_VERSION_FLAG_AND_VALUE="--kubernetes-version $KUBERNETES_VERSION"
fi

if [ "$IAAS" = "aws" ];
then
  
  MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
  kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

  mkdir -p generated/$CLUSTER_NAME

  cp config-templates/aws-workload-cluster-config.yaml generated/$CLUSTER_NAME/cluster-config.yaml

  export AWS_VPC_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.vpc.id}")
  export AWS_PUBLIC_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==true)].id}")
  export AWS_PRIVATE_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==false)].id}")

  yq e -i '.AWS_VPC_ID = env(AWS_VPC_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_PUBLIC_SUBNET_ID = env(AWS_PUBLIC_SUBNET_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_PRIVATE_SUBNET_ID = env(AWS_PRIVATE_SUBNET_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml

  tanzu cluster create --file=generated/$MANAGEMENT_CLUSTER_NAME/cluster-config.yaml -v 6

  # The following additional step is required when deploying workload clusters to the same VPC as the management cluster in order for LoadBalancers to be created properly
  aws ec2 create-tags --resources $AWS_PUBLIC_SUBNET_ID --tags Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared
elif [ "$IAAS" == "azure" ];
then
  tkg create cluster $CLUSTER_NAME \
    --enable-cluster-options oidc \
    --plan dev \
    $KUBERNETES_VERSION_FLAG_AND_VALUE \
    -w $WORKER_REPLICAS -v 6  
else
  tkg create cluster $CLUSTER_NAME \
    --enable-cluster-options oidc \
    --plan dev \
    $KUBERNETES_VERSION_FLAG_AND_VALUE \
    --vsphere-controlplane-endpoint $VSPHERE_CONTROLPLANE_ENDPOINT \
    -w $WORKER_REPLICAS -v 6
fi

tanzu cluster kubeconfig get $CLUSTER_NAME --admin

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
