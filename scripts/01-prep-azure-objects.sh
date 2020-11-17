#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

# Check if client-id is already set, if so exit 
AZURE_CLIENT_ID=$(yq r "$PARAMS_YAML" azure.client-id)
if [ -n "$AZURE_CLIENT_ID" ]; then
  echo "INFO: client id already configured in $PARAMS_YAML, not doing anything"
  exit 0
fi

# Ensure az is configured and working
if ! az account show > /dev/null; then
  echo "ERROR: could not run az account show, please configure az"
  exit 1
fi

# Get tenant id
AZURE_TENANT_ID=$(yq r "$PARAMS_YAML" azure.tenant-id)
if [ -z "$AZURE_TENANT_ID" ]; then 
    AZURE_TENANT_ID=$(az account get-access-token --query tenant --output tsv)
    yq write "$PARAMS_YAML" -i "azure.tenant-id" "$AZURE_TENANT_ID"
fi
echo "INFO: azure tenant id is $AZURE_TENANT_ID"

# Get subscription id
AZURE_SUBSCRIPTION_ID=$(yq r "$PARAMS_YAML" azure.subscription-id)
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    yq write "$PARAMS_YAML" -i "azure.subscription-id" "$AZURE_SUBSCRIPTION_ID"
fi
echo "INFO: azure subscription id is $AZURE_SUBSCRIPTION_ID"

# Set an app name - tkg-$date
AZURE_APP_NAME=$(yq r "$PARAMS_YAML" azure.app-name)
if [ -z "$AZURE_APP_NAME" ]; then
  AZURE_APP_NAME=tkg-$(date +%F-%H-%M)
  yq write "$PARAMS_YAML" -i "azure.app-name" "$AZURE_APP_NAME"
fi
echo "INFO: azure app name is $AZURE_APP_NAME"

# Generate a client secret to use when creating the azure app
AZURE_CLIENT_SECRET=$(yq r "$PARAMS_YAML" azure.client-secret)
if [ -z "$AZURE_CLIENT_SECRET" ]; then
  AZURE_CLIENT_SECRET=$(openssl rand -base64 32)
  yq write "$PARAMS_YAML" -i "azure.client-secret" "$AZURE_CLIENT_SECRET"
fi

# Create the azure app and get the client/app id
AZURE_CLIENT_ID=$(az ad app create --display-name "$AZURE_APP_NAME" \
  --homepage "http://$AZURE_APP_NAME" \
  --identifier-uris "https://$AZURE_APP_NAME" \
  --password "$AZURE_CLIENT_SECRET" | jq -r .appId)

yq write "$PARAMS_YAML" -i azure.client-id "$AZURE_CLIENT_ID"
echo "INFO: azure client id is $AZURE_CLIENT_ID"
