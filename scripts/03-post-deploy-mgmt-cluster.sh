#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
WORKER_REPLICAS=$(yq e .management-cluster.worker-replicas $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

tanzu cluster scale $MANAGEMENT_CLUSTER_NAME -n tkg-system -w $WORKER_REPLICAS

kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME

#Patch the management cluster when Cloud gate session tokens are being used.

if [ -z "$AWS_SESSION_TOKEN" ]; 
then
    echo "Management Cluster Setup Complete"
else

    # External DNS Extension needs to be able to access AWS API via IAM Instance Role
    aws iam attach-role-policy --role-name nodes.tkg.cloud.vmware.com --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess
   
    # Velere needs to be able to access AWS API via IAM Instance Role
    aws iam attach-role-policy --role-name nodes.tkg.cloud.vmware.com --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

fi

# We have found that after the tanzu cli reports that the managmement cluster is created, there are additional initialation of system pods.  In order 
# to ensure that the cluster is fully initilized, we will wait for the pinniped-supervisor job to be completed.
while kubectl get po -n pinniped-supervisor | grep Completed ; [ $? -ne 0 ]; do
	echo "Pinniped Configuration is not yet complete"
	sleep 5s
done

kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
kubectl apply -f storage-classes/default-storage-class-$IAAS.yaml
