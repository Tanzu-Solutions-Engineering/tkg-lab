#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML workload-cluster.name)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f acme-fitness/acme-fitness-namespace-settings.yaml
