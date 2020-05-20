#!/bin/bash -e

export AWS_ACCESS_KEY_ID=$(yq r $PARAM_FILE aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAM_FILE aws.secret-access-key)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)

clusterawsadm alpha bootstrap create-stack

aws ec2 delete-key-pair --key-name tkg-default
aws ec2 create-key-pair --key-name tkg-default --output json | jq .KeyMaterial -r > ./management-cluster-setup/generated/aws-ssh.pem
