#!/bin/bash -e

source ./scripts/set-env.sh

HARBOR_CN=$(yq r $PARAMS_YAML harbor.harbor-cn)
NOTARY_CN=$(yq r $PARAMS_YAML harbor.notary-cn)

mkdir -p harbor/generated/

# 01-namespace.yaml
yq read harbor/01-namespace.yaml > harbor/generated/01-namespace.yaml

# 02-certs.yaml
yq read harbor/02-certs.yaml > harbor/generated/02-certs.yaml
yq write harbor/generated/02-certs.yaml -i "spec.commonName" $HARBOR_CN
yq write harbor/generated/02-certs.yaml -i "spec.dnsNames[0]" $HARBOR_CN
yq write harbor/generated/02-certs.yaml -i "spec.dnsNames[1]" $NOTARY_CN

# harbor-values.yaml
yq read harbor/harbor-values.yaml > harbor/generated/harbor-values.yaml
yq write harbor/generated/harbor-values.yaml -i "expose.ingress.hosts.core" $HARBOR_CN
yq write harbor/generated/harbor-values.yaml -i "expose.ingress.hosts.notary" $NOTARY_CN  
yq write harbor/generated/harbor-values.yaml -i "externalURL" https://$HARBOR_CN
