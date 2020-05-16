#!/bin/bash -e

export IP=$(kubectl get svc envoy -n tanzu-system-ingress --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
export DNS_NAME=$PARAM_FILE dns.workload.name
export RECORDSET_FILE='./dns/aws-recordset-vsphere.json'

./extensions/create-record-set.sh