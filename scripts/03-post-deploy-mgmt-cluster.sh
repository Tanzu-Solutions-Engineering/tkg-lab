#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

# Wait for apps to finish reconciling
while [[ $(kubectl get apps -n tkg-system -oyaml | yq e '.items[] | select(.status.friendlyDescription != "Reconcile succeeded") | .metadata.name' | wc -l) -ne 0 ]] ; do
	echo "Waiting for apps to finish reconciling"
	sleep 5
done

tanzu cluster scale $MANAGEMENT_CLUSTER_NAME -n tkg-system -w $WORKER_REPLICAS

kubectl create ns tanzu-user-managed-packages --dry-run=client --output yaml | kubectl apply -f -
