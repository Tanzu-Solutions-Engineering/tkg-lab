#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

DNS_PROVIDER=$(yq r $PARAMS_YAML dns.provider)
LAB_SUBDOMAIN=$(yq r $PARAMS_YAML subdomain)
LAB_ENV_NAME=$(yq r $PARAMS_YAML environment-name)

if [ "$DNS_PROVIDER" = "gcloud-dns" ];
then
  # Using Google Cloud DNS
  echo "Using Google Cloud DNS"
  GCP_MANAGED_ZONE=`gcloud dns managed-zones list | grep $LAB_ENV_NAME`
  if [ -z "$GCP_MANAGED_ZONE" ]
  then
    # Create Google Cloud DNS Zone. This command will error out if zone already exists
    gcloud dns managed-zones create $LAB_ENV_NAME \
        --description="TKG "$LAB_ENV_NAME" Lab domains" \
        --dns-name=$LAB_SUBDOMAIN \
        --visibility=public
  else
    echo "Google Cloud Managed Zone $LAB_ENV_NAME already exists"
  fi
else
  # Default is to use AWS Route53
  echo "Using AWS Route53"
  AWS_HOSTED_ZONE_ID=$(yq r $PARAMS_YAML aws.hosted-zone-id)
  if [ -z "$AWS_HOSTED_ZONE_ID" ];then
    echo "AWS hosted zone id not found in cofiguration file.  Assuming it needs to be created."
    export AWS_REGION=$(yq r $PARAMS_YAML aws.region)
    export AWS_ACCESS_KEY_ID=$(yq r $PARAMS_YAML aws.access-key-id)
    export AWS_SECRET_ACCESS_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
    AWS_HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name $LAB_SUBDOMAIN --caller-reference "$LAB_SUBDOMAIN-`date`" --output json | jq .HostedZone.Id -r | cut -d'/' -f 3)
    yq write $PARAMS_YAML -i "aws.hosted-zone-id" $AWS_HOSTED_ZONE_ID
  else
    echo "AWS Hosted Zone Id found in configuration, no need to create it."
  fi
fi
