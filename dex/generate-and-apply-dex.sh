#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

export CLUSTER_NAME=$1

export DEX_CN=$(yq e .kubeapps.oidc-issuer-fqdn $PARAMS_YAML)
export DEX_URL=https://$DEX_CN
export DEX_CALLBACK_URL=$DEX_URL/oauth2/callback

export OKTA_AUTH_SERVER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OKTA_CLIENT_ID=https://$(yq e .okta.kubeapps-dex-client-id $PARAMS_YAML)
export OKTA_CLIENT_SECRET=https://$(yq e .okta.kubeapps-dex-client-secret $PARAMS_YAML)

export KUBEAPPS_FQDN=$(yq e .kubeapps.server-fqdn $PARAMS_YAML)
export KUBEAPPS_CALLBACK_URL=https://$KUBEAPPS_FQDN/oauth2/callback

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

echo "Beginning Dex install..."

mkdir -p generated/$CLUSTER_NAME/dex

kubectl apply -f dex/01-namespace.yaml


cp dex/dex-values.yaml generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".ingress.hosts.[0].host = env(DEX_CN)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".ingress.tls.[0].hosts.[0] = env(DEX_CN)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.issuer = env(DEX_URL)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.staticClients.[0].redirectURIs.[0] = env(KUBEAPPS_CALLBACK_URL)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.connectors.[0].config.issuer = env(OKTA_AUTH_SERVER_URL)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.connectors.[0].config.clientID = env(OKTA_CLIENT_ID)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.connectors.[0].config.clientSecret = env(OKTA_CLIENT_SECRET)" generated/$CLUSTER_NAME/dex/dex-values.yaml
yq e -i ".config.connectors.[0].config.redirectURI = env(DEX_CALLBACK_URL)" generated/$CLUSTER_NAME/dex/dex-values.yaml

helm repo add dex https://charts.dexidp.io
helm upgrade --install dex --namespace dex dex/dex -f generated/$CLUSTER_NAME/dex/dex-values.yaml

