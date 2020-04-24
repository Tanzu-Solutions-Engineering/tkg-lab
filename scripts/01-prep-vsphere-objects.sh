# usage: ./01-prep-vsphere-objects.sh URL USERNAME PASSWORD DATASTORE TEMPLATE_FOLDER OVA_FOLDER

export GOVC_URL=$1
export GOVC_USERNAME=$2
export GOVC_PASSWORD=$3
export GOVC_INSECURE=true
export GOVC_DATASTORE=$4

mkdir -p keys/
ssh-keygen -t rsa -b 4096 -f ./keys/tkg_rsa -q -N ""

govc import.ova -folder $5 $6/photon-3-v1.17.3_vmware.2.ova
govc vm.markastemplate $5/photon-3-kube-v1.17.3

govc import.ova -folder $5 $6/photon-3-capv-haproxy-v0.6.3_vmware.1.ova
govc vm.markastemplate $5/capv-haproxy
