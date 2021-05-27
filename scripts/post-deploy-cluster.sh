#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$1
IAAS=$(yq e .iaas $PARAMS_YAML)

tanzu cluster kubeconfig get $CLUSTER_NAME --admin

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

# We have found that after the tanzu cli reports that the managmement cluster is created, there are additional initialation of system pods.  In order 
# to ensure that the cluster is fully initilized, we will wait for the pinniped-supervisor job to be completed.
while kubectl get po -n pinniped-supervisor | grep Completed ; [ $? -ne 0 ]; do
	echo "Pinniped Configuration is not yet complete"
	sleep 5s
done

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
kubectl apply -f storage-classes/default-storage-class-$IAAS.yaml
