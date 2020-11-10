#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and gangway-fqdn as args"
  exit 1
fi
CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

GANGWAY_CN=$2

DEX_CN=$(yq r $PARAMS_YAML management-cluster.dex-fqdn)

mkdir -p generated/$CLUSTER_NAME/gangway/

# 02b-ingress.yaml
yq read tkg-extensions-mods-examples/authentication/gangway/aws/02b-ingress.yaml > generated/$CLUSTER_NAME/gangway/02b-ingress.yaml
yq write -d0 generated/$CLUSTER_NAME/gangway/02b-ingress.yaml -i "spec.virtualhost.fqdn" $GANGWAY_CN

# 03-config.yaml
cp tkg-extensions/extensions/authentication/gangway/aws/gangway-data-values.yaml.example generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml
if [ `uname -s` = 'Darwin' ]; 
then
  # clear out incorreclty formated yaml
  sed -i '' -e 's/<INSERT_DEX_CA_CERT>/''/g' generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml
  API_SERVER_URL=`kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.server}"`
  API_SERVER_CN=`echo $API_SERVER_URL | cut -d ':' -f 2 | cut -d '/' -f 3 `
else
  # clear out incorreclty formated yaml
  sed -i -e 's/<INSERT_DEX_CA_CERT>/''/g' generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml
  API_SERVER_URL=`kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.server}"`
  API_SERVER_CN=`echo $API_SERVER_URL | cut -d ':' -f 2 | cut -d '/' -f 3 `
fi

yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.config.clusterName" $CLUSTER_NAME
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.config.DEX_SVC_LB_HOSTNAME" $DEX_CN
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.config.clientID" $CLUSTER_NAME
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.config.APISERVER_URL" $API_SERVER_CN
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.secret.sessionKey" $(openssl rand -base64 32)
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.secret.clientSecret" "FOO_SECRET"
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "gangway.service.type" "NodePort"
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "dns.aws.GANGWAY_SVC_LB_HOSTNAME" $GANGWAY_CN
yq write -d0 generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -i "dex.ca" -- "$(< keys/letsencrypt-ca.pem)"

# Add in the document seperator that yq removes
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' '3i\
  ---\
  ' generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml
else
  sed -i -e '3i\
  ---\
  ' generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml
fi

cp tkg-extensions/extensions/authentication/gangway/gangway-extension.yaml  generated/$CLUSTER_NAME/gangway/gangway-extension.yaml

# Apply Gangway

kubectl apply -f tkg-extensions/extensions/authentication/gangway/namespace-role.yaml
# Using the following "apply" syntax to allow for script to be rerun
kubectl create secret generic gangway-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/gangway/gangway-data-values.yaml -n tanzu-system-auth -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f generated/$CLUSTER_NAME/gangway/gangway-extension.yaml

while kubectl get app gangway -n tanzu-system-auth | grep gangway | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo Gangway extension is not yet ready
	sleep 5s
done   

# 05-certs.yaml
yq read tkg-extensions-mods-examples/authentication/gangway/aws/05-certs.yaml > generated/$CLUSTER_NAME/gangway/05-certs.yaml
yq write -d0 generated/$CLUSTER_NAME/gangway/05-certs.yaml -i "spec.commonName" $GANGWAY_CN
yq write -d0 generated/$CLUSTER_NAME/gangway/05-certs.yaml -i "spec.dnsNames[0]" $GANGWAY_CN

# The following bit will pause the app reconciliation, then reference the valid let's ecrypt cert, which restarts gangway

# Add paused = true to stop reconciliation
sed -i '' -e 's/syncPeriod: 5m/paused: true/g' generated/$CLUSTER_NAME/gangway/gangway-extension.yaml
kubectl apply -f generated/$CLUSTER_NAME/gangway/gangway-extension.yaml

# Wait until gangway app is paused
while kubectl get app gangway -n tanzu-system-auth | grep gangway | grep "paused" ; [ $? -ne 0 ]; do
	echo Gangway extension is not yet ready
	sleep 5s
done   

kubectl apply -f generated/$CLUSTER_NAME/gangway/02b-ingress.yaml
kubectl apply -f generated/$CLUSTER_NAME/gangway/05-certs.yaml

# Wait for above certificate to be ready.  It took me about 2m20s
while kubectl get certificate gangway-cert-valid -n tanzu-system-auth | grep True ; [ $? -ne 0 ]; do
	echo Gangway cert is not yet ready
	sleep 5s
done

kubectl patch deployment gangway \
  -n tanzu-system-auth \
  --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/volumes/1/secret/secretName", "value":"gangway-cert-tls-valid"}]'
