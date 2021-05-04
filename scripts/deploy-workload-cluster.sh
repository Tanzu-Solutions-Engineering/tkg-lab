#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq e .iaas $PARAMS_YAML)
export VSPHERE_CONTROLPLANE_ENDPOINT=$3
export KUBERNETES_VERSION=$4

export CLUSTER=$1
export WORKER_REPLICAS=$2

KUBERNETES_VERSION_FLAG_AND_VALUE=""
if [ ! "$KUBERNETES_VERSION" = "null" ]; then
  KUBERNETES_VERSION_FLAG_AND_VALUE="--tkr $KUBERNETES_VERSION"
fi

mkdir -p generated/$CLUSTER

MANAGEMENT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
kubectl config use-context $MANAGEMENT_CLUSTER-admin@$MANAGEMENT_CLUSTER

if [ "$IAAS" = "aws" ];
then

  cp config-templates/aws-workload-cluster-config.yaml generated/$CLUSTER/cluster-config.yaml

  export VPC_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER -n tkg-system -ojsonpath="{.spec.networkSpec.vpc.id}")
  export PUBLIC_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==true)].id}")
  export PRIVATE_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==false)].id}")
  export REGION=$(yq e .aws.region $PARAMS_YAML)
  export SSH_KEY_NAME=tkg-$(yq e .environment-name $PARAMS_YAML)-default

  yq e -i '.AWS_VPC_ID = env(VPC_ID)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.AWS_PUBLIC_SUBNET_ID = env(PUBLIC_SUBNET_ID)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.AWS_PRIVATE_SUBNET_ID = env(PRIVATE_SUBNET_ID)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.CLUSTER_NAME = env(CLUSTER)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.AWS_REGION = env(REGION)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.AWS_SSH_KEY_NAME = env(SSH_KEY_NAME)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER/cluster-config.yaml

  tanzu cluster create --file=generated/$CLUSTER/cluster-config.yaml $KUBERNETES_VERSION_FLAG_AND_VALUE -v 6

  # The following additional step is required when deploying workload clusters to the same VPC as the management cluster in order for LoadBalancers to be created properly
  aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=kubernetes.io/cluster/$CLUSTER,Value=shared
elif [ "$IAAS" == "azure" ];
then

  cp config-templates/azure-workload-cluster-config.yaml generated/$CLUSTER/cluster-config.yaml

  export CLUSTER_CONFIG="generated/$CLUSTER/cluster-config.yaml"

  # set vars in cluster config
  yq e -i '.CLUSTER_NAME = env(CLUSTER)' "$CLUSTER_CONFIG"

  TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
  tkg_key_file="./keys/$TKG_ENVIRONMENT_NAME-ssh"
  export AZURE_SSH_PUBLIC_KEY_B64=$(base64 < "$tkg_key_file".pub | tr -d '\r\n')

  export AZURE_CLIENT_ID=$(yq e .azure.client-id $PARAMS_YAML)
  export AZURE_CLIENT_SECRET=$(yq e .azure.client-secret $PARAMS_YAML)
  export AZURE_LOCATION=$(yq e .azure.location $PARAMS_YAML)
  export AZURE_SUBSCRIPTION_ID=$(yq e .azure.subscription-id $PARAMS_YAML)
  export AZURE_TENANT_ID=$(yq e .azure.tenant-id $PARAMS_YAML)

  yq e -i '.AZURE_SSH_PUBLIC_KEY_B64 = env(AZURE_SSH_PUBLIC_KEY_B64)' "$CLUSTER_CONFIG"

  yq e -i '.AZURE_SUBSCRIPTION_ID = env(AZURE_SUBSCRIPTION_ID)' "$CLUSTER_CONFIG"
  yq e -i '.AZURE_TENANT_ID = env(AZURE_TENANT_ID)' "$CLUSTER_CONFIG"
  yq e -i '.AZURE_CLIENT_ID = env(AZURE_CLIENT_ID)' "$CLUSTER_CONFIG"
  yq e -i '.AZURE_CLIENT_SECRET = env(AZURE_CLIENT_SECRET)' "$CLUSTER_CONFIG"
  yq e -i '.AZURE_LOCATION = env(AZURE_LOCATION)' "$CLUSTER_CONFIG"

  # from cli options
  yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' "$CLUSTER_CONFIG"

  # create the cluster
  tanzu cluster create \
  --file=generated/$CLUSTER/cluster-config.yaml \
  $KUBERNETES_VERSION_FLAG_AND_VALUE \
  -v 6

else
  cp config-templates/vsphere-workload-cluster-config.yaml generated/$CLUSTER/cluster-config.yaml

  # Get vSphere configuration vars from params.yaml
  export DATASTORE=$(yq e .vsphere.datastore $PARAMS_YAML)
  export TEMPLATE_FOLDER=$(yq e .vsphere.template-folder $PARAMS_YAML)
  export DATACENTER=$(yq e .vsphere.datacenter $PARAMS_YAML)
  export NETWORK=$(yq e .vsphere.network $PARAMS_YAML)
  export TLS_THUMBPRINT=$(yq e .vsphere.tls-thumbprint $PARAMS_YAML)
  export RESOURCE_POOL=$(yq e .vsphere.resource-pool $PARAMS_YAML)
  TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
  export SSH_PUB_KEY=$(cat ./keys/$TKG_ENVIRONMENT_NAME-ssh.pub)

  # Write vars into cluster-config file
  yq e -i '.CLUSTER_NAME = env(CLUSTER)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_CONTROL_PLANE_ENDPOINT = env(VSPHERE_CONTROLPLANE_ENDPOINT)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_DATASTORE = env(DATASTORE)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_FOLDER = env(TEMPLATE_FOLDER)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_DATACENTER = env(DATACENTER)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_TLS_THUMBPRINT = strenv(TLS_THUMBPRINT)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_RESOURCE_POOL = env(RESOURCE_POOL)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_SSH_AUTHORIZED_KEY = env(SSH_PUB_KEY)' generated/$CLUSTER/cluster-config.yaml
  yq e -i '.VSPHERE_NETWORK = env(NETWORK)' generated/$CLUSTER/cluster-config.yaml

  tanzu cluster create --file=generated/$CLUSTER/cluster-config.yaml $KUBERNETES_VERSION_FLAG_AND_VALUE -v 6
fi

# Retrive admin kubeconfig
tanzu cluster kubeconfig get $CLUSTER --admin

kubectl config use-context $CLUSTER-admin@$CLUSTER

# Create namespace that the lab uses for kapp metadata
kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml

# TODO: This is a temporary fix until this is updated with the add-on.  Addresses noise logs in pinniped-concierge
kubectl apply -f tkg-extensions-mods-examples/authentication/pinniped/pinniped-rbac-extension.yaml
