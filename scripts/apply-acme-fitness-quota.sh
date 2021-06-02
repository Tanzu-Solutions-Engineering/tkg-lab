#!/bin/bash -e

CLUSTER_NAME=$(yq e .workload-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f acme-fitness/acme-fitness-namespace-settings.yaml
