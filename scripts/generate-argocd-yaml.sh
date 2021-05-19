#!/bin/bash -e

CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
export ARGOCD_CN=$(yq e .argocd.server-fqdn $PARAMS_YAML)
export ARGOCD_PASSWORD=$(yq e .argocd.password $PARAMS_YAML)
export ARGOCD_HTPASSWORD=$(htpasswd -nbBC 10 "" $ARGOCD_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')

mkdir -p generated/$CLUSTER_NAME/argocd/
cp argocd/*.yaml generated/$CLUSTER_NAME/argocd/

yq e -i '.spec.virtualhost.fqdn = env(ARGOCD_CN)' generated/$CLUSTER_NAME/argocd/httpproxy.yaml
yq e -i '.server.certificate.domain = env(ARGOCD_CN)' generated/$CLUSTER_NAME/argocd/values.yaml
yq e -i '.configs.secret.argocdServerAdminPassword = env(ARGOCD_HTPASSWORD)' generated/$CLUSTER_NAME/argocd/values.yaml
