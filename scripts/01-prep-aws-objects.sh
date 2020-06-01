#!/bin/bash -e

clusterawsadm alpha bootstrap create-stack

export AWS_REGION=$(yq r params.yaml aws.region)
export AWS_ACCESS_KEY_ID=$(yq r params.yaml aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r params.yaml aws.secret-access-key)
TKG_ENVIRONMENT_NAME=$(yq r params.yaml management-cluster.environment-name)
SSH_KEY_FILE_NAME=$MANAGEMENT_CLUSTER_ENVIRONMENT_NAME-ssh.pem

mkdir -p keys/
if [[ ! -f ./keys/$SSH_KEY_FILE_NAME ]]; then
    aws ec2 delete-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default
    aws ec2 create-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --output json | jq .KeyMaterial -r > keys/$SSH_KEY_FILE_NAME
fi
