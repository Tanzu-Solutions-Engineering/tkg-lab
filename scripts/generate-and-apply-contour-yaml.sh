#!/bin/bash -e

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kapp deploy -a contour -n tanzu-kapp -y -f tkg-extensions/ingress/contour/aws
