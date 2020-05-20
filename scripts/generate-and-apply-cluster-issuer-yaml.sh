#!/bin/bash -e

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name and challenge type (http or dns) as args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

challenge_type=$2

LETS_ENCRYPT_ACME_EMAIL=$(yq r params.yaml lets-encrypt-acme-email)

mkdir -p generated/$CLUSTER_NAME/contour/

# contour-cluster-issuer.yaml
if [ $2 == 'http' ]; then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-http.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
fi
if [ $2 == 'dns' ]; then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-dns.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
fi
yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL

kubectl apply -f generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml