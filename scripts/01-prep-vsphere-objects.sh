#!/bin/bash -e

export GOVC_URL=$(yq r params.yaml vsphere.govc_url)
export GOVC_USERNAME=$(yq r params.yaml vsphere.govc_username)
export GOVC_PASSWORD=$(yq r params.yaml vsphere.govc_password)
export GOVC_INSECURE=$(yq r params.yaml vsphere.govc_insecure)
export GOVC_DATASTORE=$(yq r params.yaml vsphere.govc_datastore)
export TEMPLATE_FOLDER=$(yq r params.yaml vsphere.template_folder)
export LOCAL_OVA_FOLDER=$(yq r params.yaml vsphere.local_ova_folder)

mkdir -p keys/
ssh-keygen -t rsa -b 4096 -f ./keys/tkg_rsa -q -N ""

govc import.ova -folder $TEMPLATE_FOLDER $LOCAL_OVA_FOLDER/photon-3-kube-v1.18.2-vmware.1.ova
govc vm.markastemplate $TEMPLATE_FOLDER/photon-3-kube-v1.18.2

govc import.ova -folder $TEMPLATE_FOLDER $LOCAL_OVA_FOLDER/photon-3-haproxy-v1.2.4-vmware.1.ova
govc vm.markastemplate $TEMPLATE_FOLDER/photon-3-haproxy-v1.2.4
