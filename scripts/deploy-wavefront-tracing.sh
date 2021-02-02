#! /bin/bash

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as args"
  exit 1
fi
CLUSTER_NAME=$1
IAAS=$(yq r params.yaml iaas)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

WAVEFRONT_API_KEY=$(yq r params.yaml wavefront.api-key)
WAVEFRONT_URL=$(yq r params.yaml wavefront.url)
WAVEFRONT_PREFIX=$(yq r params.yaml wavefront.cluster-name-prefix)
WAVEFRONT_JAEGER_NAME=$(yq r params.yaml wavefront.jaeger-app-name-prefix)
WORKLOAD_CLUSTER_NAME=$(yq r params.yaml workload-cluster.name)

# Replace cluster tag in wf-preprocessor.yml
sed -i "s/CLUSTERTAGNAME/$WAVEFRONT_PREFIX-$WORKLOAD_CLUSTER_NAME/g" wavefront/wf-preprocessor.yml

kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm upgrade --install wavefront wavefront/wavefront -f wavefront/wf-preprocessor.yml \
  --set wavefront.url=$WAVEFRONT_URL \
  --set wavefront.token=$WAVEFRONT_API_KEY \
  --set clusterName=$WAVEFRONT_PREFIX-$CLUSTER_NAME-$IAAS \
  --set proxy.args="--traceJaegerApplicationName $WAVEFRONT_JAEGER_NAME" \
  --namespace wavefront
