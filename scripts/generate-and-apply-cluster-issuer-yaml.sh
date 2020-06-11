#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/


IAAS=$(yq r $PARAMS_YAML iaas)
LETS_ENCRYPT_ACME_EMAIL=$(yq r $PARAMS_YAML lets-encrypt-acme-email)

if [ $IAAS = 'aws' ];
then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-http.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
else
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-dns.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
  kubectl create secret generic prod-route53-credentials-secret \
        --from-literal=secret-access-key=$(yq r $PARAMS_YAML aws.secret-access-key) \
        -n cert-manager
  yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.solvers[0].dns01.route53.accessKeyID" $(yq r $PARAMS_YAML aws.access-key-id)
  yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.solvers[0].dns01.route53.region" $(yq r $PARAMS_YAML aws.region)
  yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.solvers[0].dns01.route53.hostedZoneID" $(yq r $PARAMS_YAML aws.hosted-zone-id)
fi
yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL

kubectl apply -f generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
