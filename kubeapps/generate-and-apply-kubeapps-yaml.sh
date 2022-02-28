#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

export CLUSTER_NAME=$1
export OIDC_ISSUER_URL=https://$(yq e .kubeapps.oidc-issuer-fqdn $PARAMS_YAML)
export KUBEAPPS_FQDN=$(yq e .kubeapps.server-fqdn $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

echo "Beginning Kubeapps install..."

mkdir -p generated/$CLUSTER_NAME/kubeapps

# 01-namespace.yaml

cp kubeapps/01-namespace.yaml generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
export ISSUER_URL_FLAG=" --oidc-issuer-url=$OIDC_ISSUER_URL"

# kubeapps-values.yaml
cp kubeapps/kubeapps-values.yaml generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
yq e -i ".ingress.hostname = env(KUBEAPPS_FQDN)" generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
yq e -i '.authProxy.additionalFlags.[0] = env(ISSUER_URL_FLAG)' generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml

# jwt-authenticator
cp kubeapps/kubeapps-jwt-authenticator.yaml generated/$CLUSTER_NAME/kubeapps/kubeapps-jwt-authenticator.yaml
yq e -i ".spec.issuer = env(OIDC_ISSUER_URL)" generated/$CLUSTER_NAME/kubeapps/kubeapps-jwt-authenticator.yaml

kubectl apply -f generated/$CLUSTER_NAME/kubeapps/kubeapps-jwt-authenticator.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
helm upgrade --install kubeapps --namespace kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml --version=7.4.0
