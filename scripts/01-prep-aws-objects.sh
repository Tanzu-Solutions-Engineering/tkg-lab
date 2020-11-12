#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

tkg config permissions aws

export AWS_REGION=$(yq r $PARAMS_YAML aws.region)
export AWS_ACCESS_KEY_ID=$(yq r $PARAMS_YAML aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
TKG_ENVIRONMENT_NAME=$(yq r $PARAMS_YAML environment-name)
SSH_KEY_FILE_NAME=$TKG_ENVIRONMENT_NAME-ssh.pem

mkdir -p keys/
if [[ ! -f ./keys/$SSH_KEY_FILE_NAME ]]; then
    aws ec2 delete-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --region $AWS_REGION
    aws ec2 create-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --region $AWS_REGION --output json | jq .KeyMaterial -r > keys/$SSH_KEY_FILE_NAME
fi
