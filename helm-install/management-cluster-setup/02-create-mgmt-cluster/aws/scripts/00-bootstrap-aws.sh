#!/bin/bash -e

export AWS_ACCESS_KEY_ID=$(yq r $PARAM_FILE aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAM_FILE aws.secret-access-key)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)
AWS_ACCOUNT_ID=$(yq r $PARAM_FILE aws.account-id)

aws iam create-policy --policy-name AllowExternalDNSUpdates --policy-document file://./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/AllowExternalDNSUpdates.json
clusterawsadm alpha bootstrap create-stack --extra-controlplane-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates \
--extra-node-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates

aws ec2 delete-key-pair --key-name tkg-default
aws ec2 create-key-pair --key-name tkg-default --output json | jq .KeyMaterial -r > ./management-cluster-setup/generated/aws-ssh.pem
