#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
DEX_CN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)
OKTA_AUTH_SERVER_CN=$(yq r $PARAMS_YAML okta.auth-server-fqdn)
OKTA_DEX_APP_CLIENT_ID=$(yq r $PARAMS_YAML okta.dex-app-client-id)
OKTA_DEX_APP_CLIENT_SECRET=$(yq r $PARAMS_YAML okta.dex-app-client-secret)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/dex/

# 02b-ingress.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/02b-ingress.yaml > generated/$CLUSTER_NAME/dex/02b-ingress.yaml
yq write -d0 generated/$CLUSTER_NAME/dex/02b-ingress.yaml -i "spec.virtualhost.fqdn" $DEX_CN

# Prepare Dex custom configuration
yq read tkg-extensions/extensions/authentication/dex/aws/oidc/dex-data-values.yaml.example > generated/$CLUSTER_NAME/dex/dex-data-values.yaml
# Remove templated static client
yq delete -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i "dex.config.staticClients[0]"
# Set config options for OIDC, DNS ,tokens and service type
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dns.aws.DEX_SVC_LB_HOSTNAME $DEX_CN
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.CLIENT_ID $OKTA_DEX_APP_CLIENT_ID
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.CLIENT_SECRET $OKTA_DEX_APP_CLIENT_SECRET
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.issuer "https://$OKTA_AUTH_SERVER_CN/oauth2/default"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.scopes[+] "profile"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.scopes[+] "email"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.scopes[+] "groups"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.oidc.insecureEnableGroups "true"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.expiry.signingKeys "360m"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.config.expiry.idTokens "180m"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i dex.service.type "NodePort"
yq write -d0 generated/$CLUSTER_NAME/dex/dex-data-values.yaml -i ca "letsencrypt"

if [ `uname -s` = 'Darwin' ];
then
  # Add the #overlay/replace the line above scopes:
  sed -i '' -e 's/      scopes:/      #@overlay\/replace\
      scopes:/g' generated/$CLUSTER_NAME/dex/dex-data-values.yaml
  # Add in the document seperator that yq removes
  sed -i '' '3i\
  ---\
  ' generated/$CLUSTER_NAME/dex/dex-data-values.yaml
else
  # Add the #overlay/replace the line above scopes:
  sed -i -e 's/      scopes:/      #@overlay\/replace\
      scopes:/g' generated/$CLUSTER_NAME/dex/dex-data-values.yaml
  # Add in the document seperator that yq removes
  sed -i -e '3i\
  ---\
  ' generated/$CLUSTER_NAME/dex/dex-data-values.yaml
fi

kubectl apply -f tkg-extensions/extensions/authentication/dex/namespace-role.yaml
kubectl apply -f generated/$CLUSTER_NAME/dex/02b-ingress.yaml

# Using the following "apply" syntax to allow for re-run
kubectl create secret generic dex-data-values -n tanzu-system-auth -o yaml --dry-run=client \
  --from-file=values.yaml=generated/$CLUSTER_NAME/dex/dex-data-values.yaml | kubectl apply -f-

# Put the Let's Encrypt CA certificate into a configmap to add to trusted certifcates
ytt -f overlay/trust-certificate/configmap.yaml -f overlay/trust-certificate/values.yaml --ignore-unknown-comments \
  --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
  --data-value ca=letsencrypt | kubectl apply -f - -n tanzu-system-auth

# Add overlay to use let's encrypt cluster issuer and trust Let's Encrypt
kubectl create configmap dex-overlay -n tanzu-system-auth -o yaml --dry-run=client \
  --from-file=dex-overlay.yaml=tkg-extensions-mods-examples/authentication/dex/aws/oidc/dex-overlay.yaml \
  --from-file=trust-letsencrypt.yaml=overlay/trust-certificate/overlay.yaml | kubectl apply -f-

# Use a modified version of the dex-extensions that use the above overlay
kubectl apply -f tkg-extensions-mods-examples/authentication/dex/aws/oidc/dex-extension.yaml

while kubectl get app dex -n tanzu-system-auth | grep dex | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo Dex extension is not yet ready
	sleep 5s
done
