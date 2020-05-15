#!/bin/bash -e

: ${DEX_CN?"Need to set DEX_CN environment variable"}
: ${GANGWAY_CN?"Need to set GANGWAY_CN environment variable"}
: ${OKTA_AUTH_SERVER_CN?"Need to set OKTA_AUTH_SERVER_CN environment variable"}
: ${OKTA_DEX_APP_CLIENT_ID?"Need to set OKTA_DEX_APP_CLIENT_ID environment variable"}
: ${OKTA_DEX_APP_CLIENT_SECRET?"Need to set OKTA_DEX_APP_CLIENT_SECRET environment variable"}

mkdir -p clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive

# 02-service.yaml
yq read tkg-extensions/authentication/dex/aws/oidc/02-service.yaml > clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02-service.yaml
yq write -d0 clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02-service.yaml -i "spec.type" "ClusterIP"

# 02b-ingress.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/02b-ingress.yaml > clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02b-ingress.yaml
yq write -d0 clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02b-ingress.yaml -i "spec.virtualhost.fqdn" $DEX_CN

# 03-certs.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/03-certs.yaml > clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/03-certs.yaml
yq write -d0 clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/03-certs.yaml -i "spec.commonName" $DEX_CN
yq write -d0 clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/03-certs.yaml -i "spec.dnsNames[0]" $DEX_CN

# 04-cm.yaml
yq read tkg-extensions-mods-examples/authentication/dex/aws/oidc/04-cm.yaml > clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/$DEX_CN/'$DEX_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i '' -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i '' -e 's/$OKTA_AUTH_SERVER_CN/'$OKTA_AUTH_SERVER_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i '' -e 's/$OKTA_DEX_APP_CLIENT_ID/'$OKTA_DEX_APP_CLIENT_ID'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i '' -e 's/$OKTA_DEX_APP_CLIENT_SECRET/'$OKTA_DEX_APP_CLIENT_SECRET'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
else
  sed -i -e 's/$DEX_CN/'$DEX_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i -e 's/$GANGWAY_CN/'$GANGWAY_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i -e 's/$OKTA_AUTH_SERVER_CN/'$OKTA_AUTH_SERVER_CN'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i -e 's/$OKTA_DEX_APP_CLIENT_ID/'$OKTA_DEX_APP_CLIENT_ID'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
  sed -i -e 's/$OKTA_DEX_APP_CLIENT_SECRET/'$OKTA_DEX_APP_CLIENT_SECRET'/g' clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
fi