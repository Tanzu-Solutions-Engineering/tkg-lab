#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

IAAS=$(yq r $PARAMS_YAML iaas)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

# Go to the folder where we unpacked the extensions bundle
cd tkg-extensions/extensions
# Install the TMC Extensions Manager - Commented out since we already install it when attaching the cluster to TMC
# kubectl apply -f tmc-extension-manager.yaml
# Install the kapp Controller
kubectl apply -f kapp-controller.yaml

# Wait for kapp-controller pods to be Running
while kubectl get pods -n vmware-system-tmc | grep kapp-controller | grep Running ; [ $? -ne 0 ]; do
	echo kapp-controller is not yet ready
	sleep 5s
done

# Create a namespace and RBAC config for the Contour service
kubectl apply -f ingress/contour/namespace-role.yaml

# Prepare Contour custom configuration
if [ "$IAAS" = "aws" ];
then
  # aws
  yq read ingress/contour/aws/contour-data-values.yaml.example > ../../generated/$CLUSTER_NAME/contour/contour-data-values.yaml
else
  # vsphere
  yq read ingress/contour/vsphere/contour-data-values.yaml.example > ../../generated/$CLUSTER_NAME/contour/contour-data-values.yaml
  yq write -d0 ../../generated/$CLUSTER_NAME/contour/contour-data-values.yaml -i envoy.service.type LoadBalancer
fi
# sed command to be revised for linux
sed -i '' '3i\
---\
' ../../generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Create secret with custom configuration
kubectl create secret generic contour-data-values --from-file=values.yaml=../../generated/$CLUSTER_NAME/contour/contour-data-values.yaml -n tanzu-system-ingress

# Deploy Contour Extension
kubectl apply -f ingress/contour/contour-extension.yaml

# Wait until reconcile succeeds
while kubectl get app contour -n tanzu-system-ingress | grep contour | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
  echo contour extension is not yet ready
  sleep 5
done
