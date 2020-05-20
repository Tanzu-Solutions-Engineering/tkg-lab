#!/bin/bash -e

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1
ACME_FITNESS_CN=$(yq r params.yaml acme-fitness.fqdn)

mkdir -p generated/$CLUSTER_NAME/acme-fitness/
cp acme-fitness/template/acme-fitness-frontend-ingress.yaml generated/$CLUSTER_NAME/acme-fitness/

# contour-cluster-issuer.yaml
yq write -d0 generated/$CLUSTER_NAME/acme-fitness/acme-fitness-frontend-ingress.yaml -i "spec.tls[0].hosts[0]" $ACME_FITNESS_CN  
yq write -d0 generated/$CLUSTER_NAME/acme-fitness/acme-fitness-frontend-ingress.yaml -i "spec.rules[0].host" $ACME_FITNESS_CN  
