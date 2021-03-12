#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq e .iaas $PARAMS_YAML)
export VSPHERE_CONTROLPLANE_ENDPOINT=$3
export KUBERNETES_VERSION=$4

export CLUSTER_NAME=$1
export WORKER_REPLICAS=$2

KUBERNETES_VERSION_FLAG_AND_VALUE=""
if [ ! "$KUBERNETES_VERSION" = "null" ]; then
  KUBERNETES_VERSION_FLAG_AND_VALUE="--tkr $KUBERNETES_VERSION"
fi

mkdir -p generated/$CLUSTER_NAME

if [ "$IAAS" = "aws" ];
then

  MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
  kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

  cp config-templates/aws-workload-cluster-config.yaml generated/$CLUSTER_NAME/cluster-config.yaml

  export AWS_VPC_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.vpc.id}")
  export AWS_PUBLIC_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==true)].id}")
  export AWS_PRIVATE_SUBNET_ID=$(kubectl get awscluster $MANAGEMENT_CLUSTER_NAME -n tkg-system -ojsonpath="{.spec.networkSpec.subnets[?(@.isPublic==false)].id}")
  export REGION=$(yq e .aws.region $PARAMS_YAML)
  export AWS_SSH_KEY_NAME=tkg-$(yq e .environment-name $PARAMS_YAML)-default

  yq e -i '.AWS_VPC_ID = env(AWS_VPC_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_PUBLIC_SUBNET_ID = env(AWS_PUBLIC_SUBNET_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_PRIVATE_SUBNET_ID = env(AWS_PRIVATE_SUBNET_ID)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_REGION = env(REGION)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.AWS_SSH_KEY_NAME = env(AWS_SSH_KEY_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER_NAME/cluster-config.yaml

  tanzu cluster create --file=generated/$CLUSTER_NAME/cluster-config.yaml $KUBERNETES_VERSION_FLAG_AND_VALUE -v 6

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
  cp config-templates/vsphere-workload-cluster-config.yaml generated/$CLUSTER_NAME/cluster-config.yaml

  # Get vSphere configuration vars from params.yaml
  export URL=$(yq e .vsphere.server $PARAMS_YAML)
  export USERNAME=$(yq e .vsphere.username $PARAMS_YAML)
  export PASSWORD=$(yq e .vsphere.password $PARAMS_YAML)
  export DATASTORE=$(yq e .vsphere.datastore $PARAMS_YAML)
  export TEMPLATE_FOLDER=$(yq e .vsphere.template-folder $PARAMS_YAML)
  export DATACENTER=$(yq e .vsphere.datacenter $PARAMS_YAML)
  export NETWORK=$(yq e .vsphere.network $PARAMS_YAML)
  export TLS_THUMBPRINT=$(yq e .vsphere.tls-thumbprint $PARAMS_YAML)
  export RESOURCE_POOL=$(yq e .vsphere.resource-pool $PARAMS_YAML)

  # Write vars into cluster-config file
  yq e -i '.CLUSTER_NAME = env(CLUSTER_NAME)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_CONTROL_PLANE_ENDPOINT = env(VSPHERE_CONTROLPLANE_ENDPOINT)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.WORKER_MACHINE_COUNT = env(WORKER_REPLICAS)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_SERVER = env(URL)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_USERNAME = env(USERNAME)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_PASSWORD = strenv(PASSWORD)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_DATASTORE = env(DATASTORE)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_FOLDER = env(TEMPLATE_FOLDER)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_DATACENTER = env(DATACENTER)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_NETWORK = env(NETWORK)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_TLS_THUMBPRINT = strenv(TLS_THUMBPRINT)' generated/$CLUSTER_NAME/cluster-config.yaml
  yq e -i '.VSPHERE_RESOURCE_POOL = env(RESOURCE_POOL)' generated/$CLUSTER_NAME/cluster-config.yaml

  tanzu cluster create --file=generated/$CLUSTER_NAME/cluster-config.yaml $KUBERNETES_VERSION_FLAG_AND_VALUE -v 6
fi

# No need to patch the workload-cluster-pinniped-addon secret on the managent cluster and wait for it to reconcile
# This is a hack becasue the tanzu cli does not properly create that secret with the right CA for pinniped from pinniped-info secret
mkdir -p generated/$CLUSTER_NAME/pinniped
kubectl get secret $CLUSTER_NAME-pinniped-addon -n default -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`

yq e -i '.pinniped.supervisor_ca_bundle_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

add_yaml_doc_seperator generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

kubectl create secret generic $CLUSTER_NAME-pinniped-addon --from-file=values.yaml=generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml -n default -o yaml --type=tkg.tanzu.vmware.com/addon --dry-run=client | kubectl apply -f-
kubectl annotate secret $CLUSTER_NAME-pinniped-addon --overwrite -n default tkg.tanzu.vmware.com/addon-type=authentication/pinniped
kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n default tkg.tanzu.vmware.com/addon-name=pinniped
kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n default tkg.tanzu.vmware.com/cluster-name=$CLUSTER_NAME

# NOTE: You won't be able to login successfully for another 10 minutes or so, as you wait for the addon manager on mangement cluster to reconcile and update the
# pinniped-addon secret on the workload cluster.  I have not put a wait step in here so that we don't cause a blocking activity, as you can certainly use the admin
# credentials to work with the cluster.  You will know that the addon has reconciled if you do `kubectl get jobs -A` and you see that the pinniped-post-deploy job has version 2.

tanzu cluster kubeconfig get $CLUSTER_NAME --admin

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml

# TODO: This is a temporary fix until this is updated with the add-on.  Addresses noise logs in pinniped-concierge
kubectl apply -f tkg-extensions-mods-examples/authentication/pinniped/pinniped-rbac-extension.yaml
