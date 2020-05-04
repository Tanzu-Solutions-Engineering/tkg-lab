#!/bin/bash -e
: ${LETS_ENCRYPT_ACME_EMAIL?"Need to set LETS_ENCRYPT_ACME_EMAIL environment variable"}

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name (mgmt or wlc-1) and challenge type (http or dns) as args"
  exit 1
fi

cluster_name=$1
challenge_type=$2

#bin/bash
mkdir -p clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/

# contour-cluster-issuer.yaml
if [ $2 == 'http' ]; then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-http.yaml > clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
fi
if [ $2 == 'dns' ]; then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-dns.yaml > clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
fi
yq write -d0 clusters/$cluster_name/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL
