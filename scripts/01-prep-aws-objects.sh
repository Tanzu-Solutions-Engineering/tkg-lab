#!/bin/bash -e

AWS_ACCOUNT_ID=$(yq r params.yaml aws.account-id)
./externalDNS/aws/create-externaldns-policy.sh

export AWS_REGION=$(yq r params.yaml aws.region)
export AWS_ACCESS_KEY_ID=$(yq r params.yaml aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r params.yaml aws.secret-access-key)

clusterawsadm alpha bootstrap create-stack --extra-controlplane-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates \
--extra-node-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates

TKG_ENVIRONMENT_NAME=$(yq r params.yaml management-cluster.environment-name)
MANAGEMENT_CLUSTER_ENVIRONMENT_NAME=$(yq r params.yaml management-cluster.name)
SSH_KEY_FILE_NAME=$MANAGEMENT_CLUSTER_ENVIRONMENT_NAME-ssh.pem

mkdir -p keys/
if [[ ! -f ./keys/$SSH_KEY_FILE_NAME ]]; then
    aws ec2 delete-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default
    aws ec2 create-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --output json | jq .KeyMaterial -r > keys/$SSH_KEY_FILE_NAME
fi
