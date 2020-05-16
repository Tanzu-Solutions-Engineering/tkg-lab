#!/bin/bash -e

export VSPHERE_SERVER=$(yq r $PARAM_FILE vsphere.vcenterserver)
export VSPHERE_USERNAME=$(yq r $PARAM_FILE vsphere.vcenterUser)
export VSPHERE_PASSWORD=$(yq r $PARAM_FILE vsphere.vcenterPwd)
export VSPHERE_DATACENTER=$(yq r $PARAM_FILE vsphere.dataCenter)
export VSPHERE_DATASTORE=$(yq r $PARAM_FILE vsphere.datastore)
export VSPHERE_NETWORK=$(yq r $PARAM_FILE vsphere.network)
export VSPHERE_RESOURCE_POOL=$(yq r $PARAM_FILE vsphere.resourcepool)
export VSPHERE_FOLDER=$(yq r $PARAM_FILE vsphere.folder)
export VSPHERE_SSH_AUTHORIZED_KEY=$(yq r $PARAM_FILE vsphere.sshkey)

tkg init --infrastructure=vsphere --name=$(yq r $PARAM_FILE mgmtCluster.name) --plan=dev -v 5 --config=./k8/config.yaml
# default storage class
#kubectl apply -f ./k8/vSphere/default-storage-class.yaml
