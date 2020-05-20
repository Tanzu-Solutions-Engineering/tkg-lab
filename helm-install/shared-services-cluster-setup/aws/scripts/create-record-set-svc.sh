#!/bin/bash -e

export IP=$(kubectl get svc envoy -n tanzu-system-ingress -o json | jq .status.loadBalancer.ingress[0].hostname | tr -d '"')
export DNS_NAME=$(yq r $PARAM_FILE dns.svc.name)
export RECORDSET_FILE='./dns/aws-recordset.json'

./extensions/create-record-set.sh