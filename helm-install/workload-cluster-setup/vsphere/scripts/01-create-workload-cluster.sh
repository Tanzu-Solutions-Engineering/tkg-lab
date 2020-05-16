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

export OIDC_ISSUER_URL=https://$(yq r $PARAM_FILE dex.host)
# this is custom based on ldap config
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups

kubectl config use-context $(yq r $PARAM_FILE mgmtCluster.name)-admin@$(yq r $PARAM_FILE mgmtCluster.name)
export DEX_CA=$(kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D | gzip | base64)
#kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D > ./management-cluster-setup/generated/dex-ca.crt

tkg create cluster $(yq r $PARAM_FILE wlCluster.name) --plan=oidc -w 2 -v 6 --config=./k8/config.yaml
# create default storage class
kubectl apply -f ./k8/vsphere-default-storage-class.yaml
