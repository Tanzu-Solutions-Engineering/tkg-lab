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

# 02-service.yaml
yq read tkg-extensions/authentication/dex/aws/oidc/02-service.yaml > generated/$CLUSTER_NAME/dex/02-service.yaml
yq write -d0 generated/$CLUSTER_NAME/dex/02-service.yaml -i "spec.type" "ClusterIP"

# 02b-ingress.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/02b-ingress.yaml > generated/$CLUSTER_NAME/dex/02b-ingress.yaml
yq write -d0 generated/$CLUSTER_NAME/dex/02b-ingress.yaml -i "spec.virtualhost.fqdn" $DEX_CN

# 03-certs.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/03-certs.yaml > generated/$CLUSTER_NAME/dex/03-certs.yaml
yq write -d0 generated/$CLUSTER_NAME/dex/03-certs.yaml -i "spec.commonName" $DEX_CN
yq write -d0 generated/$CLUSTER_NAME/dex/03-certs.yaml -i "spec.dnsNames[0]" $DEX_CN

# 04-cm.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/04-cm.yaml > generated/$CLUSTER_NAME/dex/04-cm.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/$DEX_CN/'$DEX_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i '' -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i '' -e 's/$OKTA_AUTH_SERVER_CN/'$OKTA_AUTH_SERVER_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i '' -e 's/$OKTA_DEX_APP_CLIENT_ID/'$OKTA_DEX_APP_CLIENT_ID'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i '' -e 's/$OKTA_DEX_APP_CLIENT_SECRET/'$OKTA_DEX_APP_CLIENT_SECRET'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
else
  sed -i -e 's/$DEX_CN/'$DEX_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i -e 's/$OKTA_AUTH_SERVER_CN/'$OKTA_AUTH_SERVER_CN'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i -e 's/$OKTA_DEX_APP_CLIENT_ID/'$OKTA_DEX_APP_CLIENT_ID'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
  sed -i -e 's/$OKTA_DEX_APP_CLIENT_SECRET/'$OKTA_DEX_APP_CLIENT_SECRET'/g' generated/$CLUSTER_NAME/dex/04-cm.yaml
fi

# add the letsencrypt certificate to the configmap as another entry
yq write -d0 generated/$CLUSTER_NAME/dex/04-cm.yaml -i 'data."letsencrypt.pem"' -- "$(cat keys/letsencrypt-ca.pem)"

kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/dex/02-service.yaml
kubectl apply -f generated/$CLUSTER_NAME/dex/02b-ingress.yaml
kubectl apply -f generated/$CLUSTER_NAME/dex/03-certs.yaml
kubectl apply -f generated/$CLUSTER_NAME/dex/04-cm.yaml
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/05-rbac.yaml

# Same environment variables set previously
if kubectl -n tanzu-system-auth get secret oidc ; then
  kubectl -n tanzu-system-auth delete secret oidc 
fi

kubectl create secret generic oidc \
   --from-literal=clientId=$OKTA_DEX_APP_CLIENT_ID \
   --from-literal=clientSecret=$OKTA_DEX_APP_CLIENT_SECRET \
   -n tanzu-system-auth


#Wait for cert to be ready
while kubectl get certificates -n tanzu-system-auth dex-cert | grep True ; [ $? -ne 0 ]; do
	echo Dex certificate is not yet ready
	sleep 5s
done   

# inject the Let's Encrypt' ca cert as a trusted certificate
ytt -f tkg-extensions/authentication/dex/aws/oidc/06-deployment.yaml -f overlay/trust-certificate --ignore-unknown-comments \
    --data-value namespace=tanzu-system-auth \
    --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/dex/06-deployment.yaml
 
kubectl apply -f generated/$CLUSTER_NAME/dex/06-deployment.yaml 
