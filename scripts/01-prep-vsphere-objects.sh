#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

function echo_found() {
  message=${1:-"skipping"}
  echo -e "\033[1;32mfound\033[0m, $message"
}

function echo_notfound() {
  message=${1:-"creating"}
  echo -e "\033[1;32mnot found\033[0m, $message"
}

function ensure_upload_template() {
  template_inventory_folder=$1
  template_name=$2
  template_ova_path=$3
  if [ "$template_inventory_folder" = "" ]; then
    template_path=$template_name
  else
    template_path="$template_inventory_folder/$template_name"
  fi

  echo -n "Checking for template at $template_path: "
  if [[ "$(govc vm.info $template_path)" == *"$template_name"* ]]; then
    echo_found
  else
    echo_notfound
    govc import.ova -folder $template_inventory_folder $template_ova_path
    govc vm.markastemplate $template_inventory_folder/$template_name
  fi

}

# Get cluster name and prepare cluster-config file
export CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
mkdir -p generated/$CLUSTER_NAME
cp config-templates/vsphere-mc-config.yaml generated/$CLUSTER_NAME/cluster-config.yaml

# Get vSphere configuration vars from params.yaml
export GOVC_URL=$(yq e .vsphere.server $PARAMS_YAML)
export GOVC_USERNAME=$(yq e .vsphere.username $PARAMS_YAML)
export GOVC_PASSWORD=$(yq e .vsphere.password $PARAMS_YAML)
export GOVC_INSECURE=$(yq e .vsphere.insecure $PARAMS_YAML)
export GOVC_DATASTORE=$(yq e .vsphere.datastore $PARAMS_YAML)
export TEMPLATE_FOLDER=$(yq e .vsphere.template-folder $PARAMS_YAML)
export DATACENTER=$(yq e .vsphere.datacenter $PARAMS_YAML)
export NETWORK=$(yq e .vsphere.network $PARAMS_YAML)
export TLS_THUMBPRINT=$(yq e .vsphere.tls-thumbprint $PARAMS_YAML)
export GOVC_RESOURCE_POOL=$(yq e .vsphere.resource-pool $PARAMS_YAML)
export LOCAL_OVA_FOLDER=$(yq e .vsphere.local-ova-folder $PARAMS_YAML)

# Write vars into cluster-config file
yq e -i '.VSPHERE_SERVER = env(GOVC_URL)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_USERNAME = env(GOVC_USERNAME)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_PASSWORD = strenv(GOVC_PASSWORD)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_DATASTORE = env(GOVC_DATASTORE)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_FOLDER = env(TEMPLATE_FOLDER)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_DATACENTER = env(DATACENTER)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_NETWORK = env(NETWORK)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_TLS_THUMBPRINT = strenv(TLS_THUMBPRINT)' generated/$CLUSTER_NAME/cluster-config.yaml
yq e -i '.VSPHERE_RESOURCE_POOL = env(GOVC_RESOURCE_POOL)' generated/$CLUSTER_NAME/cluster-config.yaml
# The rest of the cluster-config needs to be set manually

# Create SSH key
mkdir -p keys/
TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
tkg_key_file="./keys/$TKG_ENVIRONMENT_NAME-ssh"
echo -n "Checking for existing SSH key at $tkg_key_file: "
if [ -f "$tkg_key_file" ]; then
  echo_found "skipping generation"
else
  echo_notfound "generating"
  ssh-keygen -t rsa -b 4096 -f $tkg_key_file -q -N ""
fi
export VSPHERE_SSH_PUB_KEY=$(cat $tkg_key_file.pub)
yq e -i '.VSPHERE_SSH_AUTHORIZED_KEY = env(VSPHERE_SSH_PUB_KEY)' generated/$CLUSTER_NAME/cluster-config.yaml

# Upload TKG k8s OVA: Both Ubuntu and Photon
# TODO: Must update exact sha's once GA version is released
ensure_upload_template $TEMPLATE_FOLDER photon-3-kube-v1.22.5 $LOCAL_OVA_FOLDER/photon-3-kube-v1.22.5+vmware.1-tkg.2-790a7a702b7fa129fb96be8699f5baa4.ova
ensure_upload_template $TEMPLATE_FOLDER ubuntu-2004-kube-v1.22.5 $LOCAL_OVA_FOLDER/ubuntu-2004-kube-v1.22.5+vmware.1-tkg.2-f838b27ca494fee7083c0340e11ce243.ova
