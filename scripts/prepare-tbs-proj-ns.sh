#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh >/dev/null 2>&1

$TKG_LAB_SCRIPTS/create-harbor-acme-project.sh

CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
HARBOR_FQDN=$(yq e .harbor.harbor-cn $PARAMS_YAML)
HARBOR_USER=$(yq e .harbor.admin-user $PARAMS_YAML)
export REGISTRY_PASSWORD=$(yq e .harbor.admin-password $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME


kubectl create ns acme-build --dry-run=client -oyaml | kubectl apply -f-
kp secret create -n acme-build acme-build-secret --registry=${HARBOR_FQDN} --registry-user=${HARBOR_USER} --dry-run --output yaml | kubectl apply -f-

# kubectl create secret docker-registry acme-build-secret -n acme-build --docker-server=${HARBOR_FQDN} \
#     --docker-username=${HARBOR_USER} --docker-password="${HARBOR_PW}" --dry-run=client -oyaml | kubectl apply -f-

