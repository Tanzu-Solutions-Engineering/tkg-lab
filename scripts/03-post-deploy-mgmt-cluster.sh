#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

# A management cluster can still be created even if the system addon apps fail to reconcile.  The following checks will break the script if an app has not succeeded reconciliation
if kubectl get app -n tkg-system | grep failed ; [ $? -ne 0 ]; then
	echo No apps have failed reconciliation, proceeding.
else
	echo An app has failed reconciliation, please troubleshoot!
	exit 1
fi

if kubectl get app -n tkg-system | grep Reconciling ; [ $? -ne 0 ]; then
	echo No apps are still reconciling, proceeding.
else
	echo An app is still reconciling, please troubleshoot!
	exit 1
fi

tanzu cluster scale $MANAGEMENT_CLUSTER_NAME -n tkg-system -w $WORKER_REPLICAS

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
kubectl apply -f storage-classes/default-storage-class-$IAAS.yaml
