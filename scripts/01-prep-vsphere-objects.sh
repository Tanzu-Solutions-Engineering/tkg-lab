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

# Get vSphere configuration vars from params.yaml
export GOVC_URL=$(yq r $PARAMS_YAML vsphere.server)
export GOVC_USERNAME=$(yq r $PARAMS_YAML vsphere.username)
export GOVC_PASSWORD=$(yq r $PARAMS_YAML vsphere.password)
export GOVC_INSECURE=$(yq r $PARAMS_YAML vsphere.insecure)
export GOVC_DATASTORE=$(yq r $PARAMS_YAML vsphere.datastore)
export TEMPLATE_FOLDER=$(yq r $PARAMS_YAML vsphere.template_folder)
export LOCAL_OVA_FOLDER=$(yq r $PARAMS_YAML vsphere.local_ova_folder)

# Write those vars into ~/.tkg/config.yaml
if [ "$TKG_CONFIG" = "" ]; then
  TKG_CONFIG=~/.tkg/config.yaml
fi
yq write $TKG_CONFIG -i "VSPHERE_SERVER" $GOVC_URL
yq write $TKG_CONFIG -i "VSPHERE_USERNAME" $GOVC_USERNAME
yq write $TKG_CONFIG -i "VSPHERE_PASSWORD" $GOVC_PASSWORD --style=double
yq write $TKG_CONFIG -i "VSPHERE_DATASTORE" $GOVC_DATASTORE
# The rest of the ~/.tkg/config.yaml need to be set manually

# A bug in tkg 1.2.1 affects binding pv's to pods that are not run as root.  This impacts harbor and prometheus.
# This can be resolved by modifying the cluster api provider manifests.  The following does this for you. The bug will be fixed in TKG 1.3
#if [ `uname -s` = 'Darwin' ];
#then
#  sed -i '' -e '400i\
#  \            - --default-fstype=ext4' ~/.tkg/providers/infrastructure-vsphere/v0.7.1/ytt/csi.lib.yaml
#else
#  sed -i -e '400i\            - --default-fstype=ext4' ~/.tkg/providers/infrastructure-vsphere/v0.7.1/ytt/csi.lib.yaml
#fi

# Create SSH key
mkdir -p keys/
tkg_key_file="./keys/tkg_rsa"
echo -n "Checking for existing SSH key at $tkg_key_file: "
if [ -f "$tkg_key_file" ]; then
  echo_found "skipping generation"
else
  echo_notfound "generating"
  ssh-keygen -t rsa -b 4096 -f ./keys/tkg_rsa -q -N ""
  yq write $TKG_CONFIG -i "VSPHERE_SSH_AUTHORIZED_KEY" "$(cat ./keys/tkg_rsa.pub)"
fi

# Upload TKG k8s OVA
ensure_upload_template $TEMPLATE_FOLDER photon-3-kube-v1.20.1 $LOCAL_OVA_FOLDER/photon-3-kube-v1.20.1+vmware.2-tkg.0-12902160816343315692.ova
# Ubuntu OVA - commented out until we parametrize the choice of OVA in the cluster config
# ensure_upload_template $TEMPLATE_FOLDER ubuntu-2004-kube-v1.20.1 $LOCAL_OVA_FOLDER/ubuntu-2004-kube-v1.20.1+vmware.2-tkg.0-15935558247135313201.ova
