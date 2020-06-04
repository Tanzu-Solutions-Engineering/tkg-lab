#!/bin/bash -e

export AWS_AMI_ID=$(yq r $PARAM_FILE aws.AWS_AMI_ID)
export AWS_NODE_AZ=$(yq r $PARAM_FILE aws.AWS_NODE_AZ)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)

export CLUSTER_NAME=$(yq r $PARAM_FILE wlCluster.name)
export WORKER_NODES=$(yq r $PARAM_FILE wlCluster.workdernodes)

./common/scripts/create-workload-cluster.sh

# create default storage class
kubectl apply -f ./k8/default-storage-class.yaml
