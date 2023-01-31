#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export AWS_REGION=$(yq e .aws.region $PARAMS_YAML)

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    export AWS_ACCESS_KEY_ID=$(yq e .aws.access-key-id $PARAMS_YAML)
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    export AWS_SECRET_ACCESS_KEY=$(yq e .aws.secret-access-key $PARAMS_YAML)
fi

tanzu management-cluster permissions aws set

TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
SSH_KEY_FILE_NAME=$TKG_ENVIRONMENT_NAME-ssh.pem

mkdir -p keys/
if [[ ! -f ./keys/$SSH_KEY_FILE_NAME ]]; then
    aws ec2 delete-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --region $AWS_REGION
    aws ec2 create-key-pair --key-name tkg-$TKG_ENVIRONMENT_NAME-default --region $AWS_REGION --output json | jq .KeyMaterial -r > keys/$SSH_KEY_FILE_NAME
fi


# Use Terraform to pave the networking. Pass in cluster names so that the appropriate tags can be put on the subnets.
MC_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
SSC_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
WLC_NAME=$(yq e .workload-cluster.name $PARAMS_YAML)
terraform -chdir=terraform/aws init
terraform -chdir=terraform/aws fmt
terraform -chdir=terraform/aws apply -auto-approve -var="mc_name=$MC_NAME" -var="ssc_name=$SCC_NAME" -var="wlc_name=$WLC_NAME" -var="aws_region=$AWS_REGION"
