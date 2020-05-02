#!/bin/bash -e
: ${AWS_ACCESS_KEY_ID?"Need to set AWS_ACCESS_KEY_ID environment variable"}
: ${AWS_SECRET_ACCESS_KEY?"Need to set AWS_SECRET_ACCESS_KEY environment variable"}
: ${AWS_REGION?"Need to set AWS_REGION environment variable"}

clusterawsadm alpha bootstrap create-stack

mkdir -p keys/
aws ec2 delete-key-pair --key-name tkg-default
aws ec2 create-key-pair --key-name tkg-default --output json | jq .KeyMaterial -r > keys/aws-ssh.pem
