#!/bin/bash -e

source ./scripts/set-env.sh

AWS_HOSTED_ZONE_ID=$(yq r $PARAMS_YAML aws.hosted-zone-id)
if [ -z "$AWS_HOSTED_ZONE_ID" ];then
  echo "AWS hosted zone id not found in cofiguration file.  Assuming it needs to be created."
  export AWS_REGION=$(yq r $PARAMS_YAML aws.region)
  export AWS_ACCESS_KEY_ID=$(yq r $PARAMS_YAML aws.access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
  LAB_SUBDOMAIN=$(yq r $PARAMS_YAML subdomain)
  AWS_HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name $LAB_SUBDOMAIN --caller-reference "$LAB_SUBDOMAIN-`date`" --output json | jq .HostedZone.Id -r | cut -d'/' -f 3)
  yq write $PARAMS_YAML -i "aws.hosted-zone-id" $AWS_HOSTED_ZONE_ID
else
  echo "AWS Hosted Zone Id found in configuration, no need to create it."
fi
