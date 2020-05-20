#!/bin/bash -e

AWS_HOSTED_ZONE_ID=$(yq r params.yaml aws.hosted-zone-id)
if [ -z "$AWS_HOSTED_ZONE_ID" ];then
  echo "AWS hosted zone id not found in cofiguration file.  Assuming it needs to be created."
  export AWS_REGION=$(yq r params.yaml aws.region)
  export AWS_ACCESS_KEY_ID=$(yq r params.yaml aws.access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(yq r params.yaml aws.secret-access-key)
  LAB_SUBDOMAIN=$(yq r params.yaml subdomain)
  AWS_HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name $LAB_SUBDOMAIN --caller-reference "$LAB_SUBDOMAIN-`date`" --output json | jq .HostedZone.Id -r | cut -d'/' -f 3)
  yq write params.yaml -i "aws.hosted-zone-id" $AWS_HOSTED_ZONE_ID
else
  echo "AWS Hosted Zone Id found in configuration, no need to create it."
fi
