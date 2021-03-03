#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

IAAS=$(yq e .iaas $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

# Install the TMC Extensions Manager - Commented out since we already install it when attaching the cluster to TMC
kubectl apply -f tkg-extensions/extensions/tmc-extension-manager.yaml

# Create a namespace and RBAC config for the Contour service
kubectl apply -f tkg-extensions/extensions/ingress/contour/namespace-role.yaml

# Prepare Contour custom configuration
cp tkg-extensions/extensions/ingress/contour/$IAAS/contour-data-values.yaml.example generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Not necessary for azure and aws, but it doesn't hurt
yq e -i '.envoy.service.type = "LoadBalancer"' generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Add in the document seperator that yq removes
add_yaml_doc_seperator generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Create secret with custom configuration
kubectl create secret generic contour-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/contour/contour-data-values.yaml -n tanzu-system-ingress -o yaml --dry-run=client | kubectl apply -f-

# Deploy Contour Extension
kubectl apply -f tkg-extensions/extensions/ingress/contour/contour-extension.yaml

# Wait until reconcile succeeds
while kubectl get app contour -n tanzu-system-ingress | grep contour | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
  echo contour extension is not yet ready
  sleep 5
done
