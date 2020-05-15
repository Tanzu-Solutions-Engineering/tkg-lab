#!/bin/bash -e

: ${GANGWAY_CN?"Need to set GANGWAY_CN environment variable"}
: ${DEX_CN?"Need to set DEX_CN environment variable"}
: ${CLUSTER_NAME?"Need to set CLUSTER_NAME environment variable"}

mkdir -p clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated

# 02-service.yaml
yq read tkg-extensions/authentication/gangway/aws/02-service.yaml > clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02-service.yaml
yq write -d0 clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02-service.yaml -i "spec.type" "ClusterIP"

# 02b-ingress.yaml
yq read tkg-extensions-mods-examples/authentication/gangway/aws/02b-ingress.yaml > clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02b-ingress.yaml
yq write -d0 clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02b-ingress.yaml -i "spec.virtualhost.fqdn" $GANGWAY_CN

# 03-config.yaml
yq read tkg-extensions-mods-examples/authentication/gangway/aws/03-config.yaml > clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/03-config.yaml
sed -i -e 's/$DEX_CN/'$DEX_CN'/g' clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/03-config.yaml
sed -i -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/03-config.yaml
WLC_1_API_SERVER_URL=`kubectl config view -o jsonpath='{.clusters[?(@.name=="'${CLUSTER_NAME}'")].cluster.server}'`
WLC_1_API_SERVER_CN=`cut -d ':' -f 2 <<< $WLC_1_API_SERVER_URL | cut -d '/' -f 3`
sed -i -e 's/$WLC_1_API_SERVER_CN/'$WLC_1_API_SERVER_CN'/g' clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/03-config.yaml

# 05-certs.yaml
yq read tkg-extensions-mods-examples/authentication/gangway/aws/05-certs.yaml > clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/05-certs.yaml
yq write -d0 clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/05-certs.yaml -i "spec.commonName" $GANGWAY_CN
yq write -d0 clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/05-certs.yaml -i "spec.dnsNames[0]" $GANGWAY_CN
