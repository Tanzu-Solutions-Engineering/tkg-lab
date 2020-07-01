#!/bin/bash -e

source ./scripts/set-env.sh

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
govc import.ova -folder $TEMPLATE_FOLDER $LOCAL_OVA_FOLDER/photon-3-kube-v1.18.2-vmware.1.ova
govc vm.markastemplate $TEMPLATE_FOLDER/photon-3-kube-v1.18.2

# Upload TKG HA Proxy OVA
govc import.ova -folder $TEMPLATE_FOLDER $LOCAL_OVA_FOLDER/photon-3-haproxy-v1.2.4-vmware.1.ova
govc vm.markastemplate $TEMPLATE_FOLDER/photon-3-haproxy-v1.2.4
