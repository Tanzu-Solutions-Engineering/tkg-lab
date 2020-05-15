# bin/bash

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi
CLUSTER_NAME=$1

WAVEFRONT_API_KEY=$(yq r params.yaml wavefront.api-key)
WAVEFRONT_URL=$(yq r params.yaml wavefront.url)
WAVEFRONT_PREFIX=$(yq r params.yaml wavefront.cluster-name-prefix)

kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm install wavefront wavefront/wavefront -f clusters/mgmt/wavefront/wf.yml \
  --set wavefront.url=$WAVEFRONT_URL \
  --set wavefront.token=$WAVEFRONT_API_KEY \
  --set clusterName=$WAVEFRONT_PREFIX-$CLUSTER_NAME \
  --namespace wavefront