#!/bin/bash -e

export AWS_ACCESS_KEY_ID=$(yq r ./params.yml aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r ./params.yml aws.secret-access-key)
export AWS_REGION=$(yq r ./params.yml aws.region)

clusterawsadm alpha bootstrap create-stack

aws ec2 delete-key-pair --key-name tkg-default
aws ec2 create-key-pair --key-name tkg-default --output json | jq .KeyMaterial -r > ./management-cluster-setup/generated/aws-ssh.pem