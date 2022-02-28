#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

DNS_PROVIDER=$(yq e .dns.provider $PARAMS_YAML )
LAB_SUBDOMAIN=$(yq e .subdomain $PARAMS_YAML)
LAB_ENV_NAME=$(yq e .environment-name $PARAMS_YAML)

if [ "$DNS_PROVIDER" = "gcloud-dns" ];
then
  # Using Google Cloud DNS
  echo "Using Google Cloud DNS"
  GCP_MANAGED_ZONE=$(gcloud dns managed-zones list | { grep $LAB_ENV_NAME || true; } )
  echo "GCP_MANAGED_ZONE=$GCP_MANAGED_ZONE"
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
elif [ "$DNS_PROVIDER" = "azure-dns" ];
then
  AZURE_DNZ_ZONE_NAME=$(yq e .subdomain $PARAMS_YAML)
  export AZURE_ZONE_RESOURCE_GROUP_NAME=$(az network dns zone list -o tsv --query "[?name=='$AZURE_DNZ_ZONE_NAME'].resourceGroup")
  if [ -z "$AZURE_ZONE_RESOURCE_GROUP_NAME" ]
  then

    # zone does not exist, need to create it.
    # create group, zone

    export AZURE_ZONE_RESOURCE_GROUP_NAME=tkg-lab-dns
    echo "INFO: Creating $AZURE_ZONE_RESOURCE_GROUP_NAME resource group"
    az group create -n $AZURE_ZONE_RESOURCE_GROUP_NAME -l $(yq e '.azure.location' $PARAMS_YAML)
    
    export AZURE_RESOURCE_GROUP_ID=$(az group show -n $AZURE_ZONE_RESOURCE_GROUP_NAME --query id --output tsv)

    echo "INFO: Creating dns zone within resource group"
    az network dns zone create -g $AZURE_ZONE_RESOURCE_GROUP_NAME -n $(yq e .subdomain $PARAMS_YAML)

  else 
    echo "INFO: DNS zone already exists"
    export AZURE_RESOURCE_GROUP_ID=$(az group show -n $AZURE_ZONE_RESOURCE_GROUP_NAME --query id --output tsv)
  fi

  # zone exists, must now see if we have a SP
  VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
  AZURE_SERVICE_PRINCIPAL=`az ad sp list -o tsv --filter "displayname eq '$VMWARE_ID-tkg-lab-dns-operator'"`
  if [ -z "$AZURE_SERVICE_PRINCIPAL" ]
  then
    # no sp, so need to create one
    echo "INFO: Creating service priciple with contributor rights on the resource group"
    RETURNED_SP_JSON=$(az ad sp create-for-rbac -n $VMWARE_ID-tkg-lab-dns-operator --role Contributor --scopes $AZURE_RESOURCE_GROUP_ID)
    echo "DEBUG: RETURNED_SP_JSON is $RETURNED_SP_JSON"

    # Setup variables from resulting json
    export AZURE_CLIENT_ID=$(echo "$RETURNED_SP_JSON" | jq -r '.appId')
    export AZURE_CLIENT_SECRET=$(echo "$RETURNED_SP_JSON" | jq -r '.password')
    export AZURE_TENANT_ID=$(echo "$RETURNED_SP_JSON" | jq -r '.tenant')
    export AZURE_SUBSCRIPTION_ID=$(yq e '.azure.subscription-id' $PARAMS_YAML)

    yq e '.tenantId = env(AZURE_TENANT_ID)' --null-input > keys/azure-dns-credentials.yaml
    yq e -i '.subscriptionId = env(AZURE_SUBSCRIPTION_ID)' keys/azure-dns-credentials.yaml
    yq e -i '.resourceGroup = env(AZURE_ZONE_RESOURCE_GROUP_NAME)' keys/azure-dns-credentials.yaml
    yq e -i '.aadClientId = env(AZURE_CLIENT_ID)' keys/azure-dns-credentials.yaml
    yq e -i '.aadClientSecret = env(AZURE_CLIENT_SECRET)' keys/azure-dns-credentials.yaml

    yq eval --output-format=json keys/azure-dns-credentials.yaml > keys/azure-dns-credentials.json
    rm keys/azure-dns-credentials.yaml
  fi

else
  # Default is to use AWS Route53
  echo "Using AWS Route53"
  AWS_HOSTED_ZONE_ID=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
  if [ -z "$AWS_HOSTED_ZONE_ID" ];then
    echo "AWS hosted zone id not found in cofiguration file.  Assuming it needs to be created."
    export AWS_REGION=$(yq e .aws.region $PARAMS_YAML)
    export AWS_ACCESS_KEY_ID=$(yq e .aws.access-key-id $PARAMS_YAML)
    export AWS_SECRET_ACCESS_KEY=$(yq e .aws.secret-access-key $PARAMS_YAML)
    export AWS_HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name $LAB_SUBDOMAIN --caller-reference "$LAB_SUBDOMAIN-`date`" --output json | jq .HostedZone.Id -r | cut -d'/' -f 3)
    yq e -i '.aws.hosted-zone-id = env(AWS_HOSTED_ZONE_ID)' $PARAMS_YAML
  else
    echo "AWS Hosted Zone Id found in configuration, no need to create it."
  fi
fi
