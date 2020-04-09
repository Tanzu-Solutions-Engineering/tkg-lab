#!/bin/bash -e
: ${LETS_ENCRYPT_ACME_EMAIL?"Need to set LETS_ENCRYPT_ACME_EMAIL environment variable"}

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name (mgmt or wlc-1) as arg"
  exit 1
fi

cluster_name=$1

#bin/bash
mkdir -p clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/

# contour-cluster-issuer.yaml
yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer.yaml > clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
yq write -d0 clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL  
