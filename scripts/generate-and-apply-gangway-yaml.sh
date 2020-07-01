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

# 02-service.yaml
yq read tkg-extensions/authentication/gangway/aws/02-service.yaml > generated/$CLUSTER_NAME/gangway/02-service.yaml
yq write -d0 generated/$CLUSTER_NAME/gangway/02-service.yaml -i "spec.type" "ClusterIP"

# 02b-ingress.yaml
yq read $TKG_LAB_SCRIPTS/../tkg-extensions-mods-examples/authentication/gangway/aws/02b-ingress.yaml > generated/$CLUSTER_NAME/gangway/02b-ingress.yaml
yq write -d0 generated/$CLUSTER_NAME/gangway/02b-ingress.yaml -i "spec.virtualhost.fqdn" $GANGWAY_CN

# 03-config.yaml
yq read $TKG_LAB_SCRIPTS/../tkg-extensions-mods-examples/authentication/gangway/aws/03-config.yaml > generated/$CLUSTER_NAME/gangway/03-config.yaml
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/$DEX_CN/'$DEX_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  sed -i '' -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  sed -i '' -e 's/$WORKLOAD_CLUSTER_NAME/'$CLUSTER_NAME'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  API_SERVER_URL=`kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.server}"`
  API_SERVER_CN=`echo $API_SERVER_URL | cut -d ':' -f 2 | cut -d '/' -f 3 `
  sed -i '' -e 's/$APISERVER_URL/'$API_SERVER_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
else
  sed -i -e 's/$DEX_CN/'$DEX_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  sed -i -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  sed -i -e 's/$WORKLOAD_CLUSTER_NAME/'$CLUSTER_NAME'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
  API_SERVER_URL=`kubectl config view -o jsonpath="{.clusters[?(@.name=='$CLUSTER_NAME')].cluster.server}"`
  API_SERVER_CN=`echo $API_SERVER_URL | cut -d ':' -f 2 | cut -d '/' -f 3 `
  sed -i -e 's/$APISERVER_URL/'$API_SERVER_CN'/g' generated/$CLUSTER_NAME/gangway/03-config.yaml
fi

# 05-certs.yaml
yq read $TKG_LAB_SCRIPTS/../tkg-extensions-mods-examples/authentication/gangway/aws/05-certs.yaml > generated/$CLUSTER_NAME/gangway/05-certs.yaml
yq write -d0 generated/$CLUSTER_NAME/gangway/05-certs.yaml -i "spec.commonName" $GANGWAY_CN
yq write -d0 generated/$CLUSTER_NAME/gangway/05-certs.yaml -i "spec.dnsNames[0]" $GANGWAY_CN


# Apply DEX

kubectl apply -f tkg-extensions/authentication/gangway/aws/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/gangway/02-service.yaml
kubectl apply -f generated/$CLUSTER_NAME/gangway/02b-ingress.yaml
kubectl apply -f generated/$CLUSTER_NAME/gangway/03-config.yaml
# Below is FOO_SECRET intentionally hard coded
kubectl create secret generic gangway \
   --from-literal=sessionKey=$(openssl rand -base64 32) \
   --from-literal=clientSecret=FOO_SECRET \
   -n tanzu-system-auth
kubectl apply -f generated/$CLUSTER_NAME/gangway/05-certs.yaml

# Wait for above certificate to be ready.  It took me about 2m20s
while kubectl get certificate gangway-cert -n tanzu-system-auth | grep True ; [ $? -ne 0 ]; do
	echo Gangway cert is not yet ready
	sleep 5s
done

kubectl create cm dex-ca -n tanzu-system-auth --from-file=dex-ca.crt=keys/letsencrypt-ca.pem

# Hack the mispelling in the tkg-extensions.  This has been fixed in an upcoming release
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/sesssionKey/sessionKey/g' tkg-extensions/authentication/gangway/aws/06-deployment.yaml
else
  sed -i -e 's/sesssionKey/sessionKey/g' tkg-extensions/authentication/gangway/aws/06-deployment.yaml
fi

kubectl apply -f tkg-extensions/authentication/gangway/aws/06-deployment.yaml

