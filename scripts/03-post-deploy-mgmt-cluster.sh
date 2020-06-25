#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
MANAGEMENT_CLUSTER_WORKER_REPLICAS=$(yq r $PARAMS_YAML management-cluster.worker-replicas)

tkg scale cluster $MANAGEMENT_CLUSTER_NAME --namespace tkg-system -w $MANAGEMENT_CLUSTER_WORKER_REPLICAS

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

$DIR/set-default-storage-class.sh
