#!/bin/bash -e

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name and host_name as args"
  exit 1
fi

CLUSTER_NAME=$1
HOST_NAME=$2

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/

yq read tkg-extensions/ingress/contour/aws/02-service-envoy.yaml > generated/$CLUSTER_NAME/contour/02-service-envoy.yaml
yq write -d0 generated/$CLUSTER_NAME/contour/02-service-envoy.yaml -i 'metadata.annotations."external-dns.alpha.kubernetes.io/hostname"' "$HOST_NAME"

cp tkg-extensions/ingress/contour/aws/01-contour-config.yaml generated/$CLUSTER_NAME/contour/01-contour-config.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/# leaderelection:/  leaderelection:/g' generated/$CLUSTER_NAME/contour/01-contour-config.yaml
  sed -i '' -e 's/#   configmap-/    configmap-/g' generated/$CLUSTER_NAME/contour/01-contour-config.yaml
else
  sed -i -e 's/# leaderelection:/  leaderelection:/g' generated/$CLUSTER_NAME/contour/01-contour-config.yaml
  sed -i -e 's/#   configmap-/    configmap-/g' generated/$CLUSTER_NAME/contour/01-contour-config.yaml
fi

kubectl apply -f tkg-extensions/ingress/contour/aws/00-common.yaml
kubectl apply -f generated/$CLUSTER_NAME/contour/01-contour-config.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/01-crds.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/02-certs-selfsigned.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/02-rbac.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/02-service-contour.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/03-contour.yaml
kubectl apply -f tkg-extensions/ingress/contour/aws/03-envoy.yaml
kubectl apply -f generated/$CLUSTER_NAME/contour/02-service-envoy.yaml
sleep 10s #Wait a sec to get DNS/IP assigned