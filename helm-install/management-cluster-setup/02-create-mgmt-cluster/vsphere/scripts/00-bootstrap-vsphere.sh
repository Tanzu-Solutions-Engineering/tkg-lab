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
export OVA_FOLDER=$(yq r $PARAM_FILE vsphere.ovafolder)
export PHOTON_OVA=$(yq r $PARAM_FILE vsphere.phtonosova)
export HAPROXY_OVA=$(yq r $PARAM_FILE vsphere.haproxyova)

echo 'creating resource pool'
govc pool.create $GOVC_RESOURCE_POOL
echo 'creating folder'
govc folder.create $GOVC_FOLDER

#echo 'importing ova'
govc import.spec $OVA_FOLDER/$PHOTON_OVA | jq '.Name="'$PHOTON_OVA'"' | jq '.NetworkMapping[0].Network="'$GOVC_NETWORK'"' | jq '.MarkAsTemplate=true' > ./generated/$PHOTON_OVA.json
govc import.ova -options=./generated/$PHOTON_OVA.json $OVA_FOLDER/$PHOTON_OVA

govc import.spec $OVA_FOLDER/$HAPROXY_OVA | jq '.Name="'$HAPROXY_OVA'"' | jq '.NetworkMapping[0].Network="'$GOVC_NETWORK'"' | jq '.MarkAsTemplate=true'> ./generated/$HAPROXY_OVA.json
govc import.ova -options=./generated/$HAPROXY_OVA.json $OVA_FOLDER/$HAPROXY_OVA

#echo 'creating content library'
#govc library.create -sub-ondemand=true -sub $CONTENT_LIBRARY_URL tkg-on-vmc-cl
#echo 'creating resource pool'
#govc pool.create $GOVC_RESOURCE_POOL
#echo 'creating folder'
#govc folder.create $GOVC_FOLDER
#echo 'Deploying Demo appliance'
#govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_demo_vm_options.json /tkg-on-vmc-cl/TKG-Demo-Appliance_1.0.0 TKG-Demo-Appliance
#echo 'Creating photon template'
#govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_photon_os_vm_options.json /tkg-on-vmc-cl/photon-3-v1.17.3_vmware.2
#echo 'Creating haproxy template'
#govc library.deploy -folder=$GOVC_FOLDER -options=./management-cluster-setup/02-create-mgmt-cluster/vSphere/lib/tkg_ha_proxy_vm_options.json /tkg-on-vmc-cl/photon-3-capv-haproxy-v0.6.3_vmware.1
#echo 'bootstrapping done!'

export PARAM_FILE=./params.yml
#govc object.mv /Datacenter/vm/photon-3-v1.17.3+vmware.2 /Datacenter/vm/tkg
#govc object.mv /Datacenter/vm/capv-haproxy-v0.6.2 /Datacenter/vm/tkg
#govc snapshot.create -vm photon-3-v1.17.3+vmware.1 root
#govc vm.markastemplate photon-3-v1.17.3+vmware.1
#govc snapshot.create -vm capv-haproxy-v0.6.2 root
#govc vm.markastemplate capv-haproxy-v0.6.2