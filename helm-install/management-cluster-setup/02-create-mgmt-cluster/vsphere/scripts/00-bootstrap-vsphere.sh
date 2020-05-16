#!/bin/bash -e

export GOVC_URL=$(yq r $PARAM_FILE vsphere.vcenterserver)
export GOVC_USERNAME=$(yq r $PARAM_FILE vsphere.vcenterUser)
export GOVC_PASSWORD=$(yq r $PARAM_FILE vsphere.vcenterPwd)
export GOVC_DATACENTER=$(yq r $PARAM_FILE vsphere.dataCenter)
export GOVC_NETWORK=$(yq r $PARAM_FILE vsphere.network)
export GOVC_DATASTORE=$(yq r $PARAM_FILE vsphere.datastore)
export GOVC_RESOURCE_POOL=$(yq r $PARAM_FILE vsphere.resourcepool)
export GOVC_INSECURE=1
export GOVC_FOLDER=$(yq r $PARAM_FILE vsphere.folder)


govc library.create -sub-ondemand=true -sub https://download3.vmware.com/software/vmw-tools/tkg-demo-appliance/cl/lib.json tkg-on-vmc-cl
sleep 5s
govc pool.create $GOVC_RESOURCE_POOL
govc folder.create $GOVC_FOLDER
govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_demo_vm_options.json /tkg-on-vmc-cl/TKG-Demo-Appliance_1.0.0 TKG-Demo-Appliance
govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_photon_os_vm_options.json /tkg-on-vmc-cl/photon-3-v1.17.3_vmware.2
govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_ha_proxy_vm_options.json /tkg-on-vmc-cl/photon-3-capv-haproxy-v0.6.3_vmware.1

#govc object.mv /Datacenter/vm/photon-3-v1.17.3+vmware.2 /Datacenter/vm/tkg
#govc object.mv /Datacenter/vm/capv-haproxy-v0.6.2 /Datacenter/vm/tkg
#govc snapshot.create -vm photon-3-v1.17.3+vmware.1 root
#govc vm.markastemplate photon-3-v1.17.3+vmware.1
#govc snapshot.create -vm capv-haproxy-v0.6.2 root
#govc vm.markastemplate capv-haproxy-v0.6.2