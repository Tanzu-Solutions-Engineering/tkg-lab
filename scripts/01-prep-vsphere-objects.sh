#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

function echo_found() {
  echo -e "found, skipping"
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

# Get vSphere configuration vars from params.yaml
export GOVC_URL=$(yq r $PARAMS_YAML vsphere.server)
export GOVC_USERNAME=$(yq r $PARAMS_YAML vsphere.username)
export GOVC_PASSWORD=$(yq r $PARAMS_YAML vsphere.password)
export GOVC_INSECURE=$(yq r $PARAMS_YAML vsphere.insecure)
export GOVC_DATASTORE=$(yq r $PARAMS_YAML vsphere.datastore)
export TEMPLATE_FOLDER=$(yq r $PARAMS_YAML vsphere.template_folder)
export LOCAL_OVA_FOLDER=$(yq r $PARAMS_YAML vsphere.local_ova_folder)
# Write those vars into ~/.tkg/config.yaml
yq write ~/.tkg/config.yaml -i "VSPHERE_SERVER" $GOVC_URL
yq write ~/.tkg/config.yaml -i "VSPHERE_USERNAME" $GOVC_USERNAME
yq write ~/.tkg/config.yaml -i "VSPHERE_PASSWORD" $GOVC_PASSWORD --style=double
yq write ~/.tkg/config.yaml -i "VSPHERE_DATASTORE" $GOVC_DATASTORE
# The rest of the ~/.tkg/config.yaml need to be set manually

# Create SSH key
mkdir -p keys/
ssh-keygen -t rsa -b 4096 -f ./keys/tkg_rsa -q -N ""

# Upload TKG k8s OVA
ensure_upload_template $TEMPLATE_FOLDER photon-3-kube-v1.18.2 $LOCAL_OVA_FOLDER/photon-3-kube-v1.18.2-vmware.1.ova

# Upload TKG HA Proxy OVA
ensure_upload_template $TEMPLATE_FOLDER photon-3-haproxy-v1.2.4 $LOCAL_OVA_FOLDER/photon-3-haproxy-v1.2.4-vmware.1.ova
