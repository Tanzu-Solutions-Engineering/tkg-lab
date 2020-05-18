#!/bin/bash

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
export API_KEY=$(yq r ./params.yml wavefront.apiKey)
export VMWARE_ID=$(yq r ./params.yml vmware.id)

helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
kubectl create namespace wavefront

helm install wavefront wavefront/wavefront \
  --set wavefront.url=https://surf.wavefront.com \
  --set wavefront.token=$API_KEY \
  --set clusterName=$VMWARE_ID-$CLUSTER_NAME \
  --namespace wavefront --replace