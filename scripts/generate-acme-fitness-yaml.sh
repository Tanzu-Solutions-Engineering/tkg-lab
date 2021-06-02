#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1
export ACME_FITNESS_CN=$(yq e .acme-fitness.fqdn $PARAMS_YAML)

mkdir -p generated/$CLUSTER_NAME/acme-fitness/
cp acme-fitness/template/acme-fitness-frontend-ingress.yaml generated/$CLUSTER_NAME/acme-fitness/

# Create the ingress to access acme fitness website
yq e -i ".spec.tls[0].hosts[0] = env(ACME_FITNESS_CN)" generated/$CLUSTER_NAME/acme-fitness/acme-fitness-frontend-ingress.yaml 
yq e -i ".spec.rules[0].host = env(ACME_FITNESS_CN)" generated/$CLUSTER_NAME/acme-fitness/acme-fitness-frontend-ingress.yaml  
