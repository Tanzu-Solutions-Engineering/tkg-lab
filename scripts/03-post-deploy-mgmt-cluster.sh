#!/bin/bash -e

MANAGEMENT_CLUSTER_NAME=$(yq r params.yaml management-cluster.name)
MANAGEMENT_CLUSTER_WORKER_REPLICAS=$(yq r params.yaml management-cluster.worker-replicas)

tkg scale cluster $MANAGEMENT_CLUSTER_NAME --namespace tkg-system -w $MANAGEMENT_CLUSTER_WORKER_REPLICAS

./scripts/set-default-storage-class.sh
