#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as arg"
  exit 1
fi

CLUSTER_NAME=$1
IAAS=$(yq e .iaas $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

# Not necessary for azure and aws, but it doesn't hurt
yq e '.envoy.service.type = "LoadBalancer"' --null-input > generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Double check the version number form above list command and update below as necessary
VERSION=$(tanzu package available list contour.tanzu.vmware.com -oyaml | yq eval ".[0].version" -)
tanzu package install contour \
    --package-name contour.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Contour would not spinup an http listener on the envoy service until an http ingress or httpproxy is created
# Specifically for AWS, the load balancer created for the envoy service, uses the http port on the node port
# for health check.  This causes a problems with our auth services which use a httpproxy with tls pass through
# as that does not activate the http listen and thus doesn't set AWS load balancers to active.  By deploying this
# service and httpproxy with non-tls endpoint, we activate the load balancer's health check
kubectl apply -f tkg-extensions-mods-examples/ingress/contour/warm-up-envoy.yaml
