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

# The default for vSphere is NodePort for envoy, so we must set it to LoadBalancer.  The following is not necessary for azure and aws, but it doesn't hurt.
yq e '.envoy.service.type = "LoadBalancer"' --null-input > generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# See TKG-4309.  TKG modified the default for contour to Cluster.  Setting back to TCE defualt which is Local.  Amongst other things, this allows for SourceIP to be preserved and in cases where there is only
# SSL HTTPProxy, allows contour to satisfy the AWS LoadBalance Healthcheck.
yq e -i '.envoy.service.externalTrafficPolicy = "Local"' generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Retrieve the most recent version number.  There may be more than one version available and we are assuming that the most recent is listed last,
# thus supplying -1 as the index of the array
VERSION=$(tanzu package available list -oyaml | yq eval '.[] | select(.display-name == "contour") | .latest-version' -)
tanzu package install contour \
    --package-name contour.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/contour/contour-data-values.yaml \
    --poll-timeout 10m0s
