#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
MANAGEMENT_CLUSTER_WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)

#TODO: Consider doing this via step 2
# tanzu cluster scale $MANAGEMENT_CLUSTER_NAME --namespace tkg-system -w $MANAGEMENT_CLUSTER_WORKER_REPLICAS

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

while kubectl get po -n pinniped-supervisor | grep Completed ; [ $? -ne 0 ]; do
	echo "Pinniped Configuration is not yet complete"
	sleep 5s
done

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
