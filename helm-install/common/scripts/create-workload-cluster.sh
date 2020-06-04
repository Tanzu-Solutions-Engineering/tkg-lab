#!/bin/bash -e

export OIDC_ISSUER_URL=https://$(yq r $PARAM_FILE dex.host)
# this is custom based on ldap config
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups

kubectl config use-context $(yq r $PARAM_FILE mgmtCluster.name)-admin@$(yq r $PARAM_FILE mgmtCluster.name)
export DEX_CA=$(kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D | gzip | base64)
#kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D > ./shared-services-cluster-setup/generated/dex-ca.crt

tkg create cluster $CLUSTER_NAME --plan=oidc -w $WORKER_NODES -v 6 --config=./k8/config.yaml