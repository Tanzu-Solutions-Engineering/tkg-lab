#!/bin/bash -e

source ./scripts/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
MANAGEMENT_CLUSTER_WORKER_REPLICAS=$(yq r $PARAMS_YAML management-cluster.worker-replicas)

tkg scale cluster $MANAGEMENT_CLUSTER_NAME --namespace tkg-system -w $MANAGEMENT_CLUSTER_WORKER_REPLICAS

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

./scripts/set-default-storage-class.sh
