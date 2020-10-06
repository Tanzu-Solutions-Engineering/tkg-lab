#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1
DEX_FQDN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)
KUBEAPPS_FQDN=$(yq r $PARAMS_YAML kubeapps.server-fqdn)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

echo "Beginning Kubeapps install..."

mkdir -p generated/$CLUSTER_NAME/kubeapps

# 01-namespace.yaml
yq read kubeapps/01-namespace.yaml > generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml

# kubeapps-values.yaml
yq read kubeapps/kubeapps-values.yaml > generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "ingress.hostname" "$KUBEAPPS_FQDN"
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "authProxy.clientID" "$CLUSTER_NAME"
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "authProxy.additionalFlags"[+]  " --oidc-issuer-url=https://$DEX_FQDN" 
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "authProxy.additionalFlags"[+]  " --scope=openid email groups"


helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
helm upgrade --install kubeapps --namespace kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
