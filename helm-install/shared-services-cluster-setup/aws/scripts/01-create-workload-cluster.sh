#!/bin/bash -e

export AWS_AMI_ID=$(yq r $PARAM_FILE aws.AWS_AMI_ID)
export AWS_NODE_AZ=$(yq r $PARAM_FILE aws.AWS_NODE_AZ)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)

export OIDC_ISSUER_URL=https://$(yq r $PARAM_FILE dex.host)
# this is custom based on ldap config
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups

kubectl config use-context $(yq r $PARAM_FILE mgmtCluster.name)-admin@$(yq r $PARAM_FILE mgmtCluster.name)
export DEX_CA=$(kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D | gzip | base64)
#kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D > ./shared-services-cluster-setup/generated/dex-ca.crt

tkg create cluster $(yq r $PARAM_FILE svcCluster.name) --plan=oidc -w 2 -v 6 --config=./k8/config.yaml
# create default storage class
kubectl apply -f ./k8/default-storage-class.yaml
