#!/bin/bash -e

kubectl config use-context $(yq r $PARAM_FILE mgmtCluster.name)-admin@$(yq r $PARAM_FILE mgmtCluster.name)

helm install dex ./tkg-extensions-helm-charts/dex-0.1.0.tgz \
--set svcCluster.gangway=$(yq r $PARAM_FILE svcCluster.gangway) \
--set svcCluster.id=$(yq r $PARAM_FILE svcCluster.name) \
--set svcCluster.name=$(yq r $PARAM_FILE svcCluster.name) \
--set wlCluster.id=$(yq r $PARAM_FILE wlCluster.name) \
--set wlCluster.name=$(yq r $PARAM_FILE wlCluster.name) \
--set svcCluster.secret=$(yq r $PARAM_FILE svcCluster.secret) \
--set wlCluster.secret=$(yq r $PARAM_FILE wlCluster.secret) \
--set wlCluster.gangway=$(yq r $PARAM_FILE wlCluster.gangway) \
--set oidc.oidcUrl=$(yq r $PARAM_FILE oidc.oidcUrl) \
--set oidc.oidcClientId=$(yq r $PARAM_FILE oidc.oidcClientId) \
--set oidc.oidcClientSecret=$(yq r $PARAM_FILE oidc.oidcClientSecret) \
--set ingress.host=$(yq r $PARAM_FILE dex.host) --wait

kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -D > ./management-cluster-setup/generated/dex-ca.crt