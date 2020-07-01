#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
ARGOCD_CN=$(yq r $PARAMS_YAML argocd.server-fqdn)
ARGOCD_PASSWORD=$(yq r $PARAMS_YAML argocd.password)

mkdir -p generated/$CLUSTER_NAME/argocd/
cp argocd/*.yaml generated/$CLUSTER_NAME/argocd/

yq write -d0 generated/$CLUSTER_NAME/argocd/httpproxy.yaml -i "spec.virtualhost.fqdn" $ARGOCD_CN
yq write -d0 generated/$CLUSTER_NAME/argocd/values.yaml -i "configs.secret.argocdServerAdminPassword" `htpasswd -nbBC 10 "" $ARGOCD_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/'`
yq write -d0 generated/$CLUSTER_NAME/argocd/values.yaml -i "server.certificate.domain" $ARGOCD_CN
