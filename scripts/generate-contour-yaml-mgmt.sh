#bin/bash
mkdir -p clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/

# contour-cluster-issuer.yaml
yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer.yaml > clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
yq write -d0 clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL  
