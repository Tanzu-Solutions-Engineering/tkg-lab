#!/bin/bash -e

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

DEX_FQDN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)
KUBEAPPS_FQDN=$(yq r $PARAMS_YAML kubeapps.fqdn)

mkdir -p generated/$CLUSTER_NAME/kubeapps

# 01-namespace.yaml
yq read kubeapps/01-namespace.yaml > generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml

# kubeapps-values.yaml
yq read kubeapps/kubeapps-values.yaml > generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "ingress.hostname" "$KUBEAPPS_FQDN"
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "authProxy.additionalFlags"[+]  " -oidc-issuer-url=$DEX_FQDN" 
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "authProxy.additionalFlags"[+]  " -scope=openid email groups"
