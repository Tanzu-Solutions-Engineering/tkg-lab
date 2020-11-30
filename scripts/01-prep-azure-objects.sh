#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

#
# Setup and preflight checks
#


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

if [ "$TKG_CONFIG" = "" ]; then
  TKG_CONFIG=~/.tkg/config.yaml
fi

if [ ! -f "$TKG_CONFIG" ]; then
  # Create ~/.tkg
  tkg get mc > /dev/null
fi

#
# Configure
#

# Get subscription id
AZURE_SUBSCRIPTION_ID=$(yq r "$PARAMS_YAML" azure.subscription-id)
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
fi

# Create an app name - tkg-$date
AZURE_APP_NAME=$(yq r "$PARAMS_YAML" azure.app-name)
if [ -z "$AZURE_APP_NAME" ]; then
  AZURE_APP_NAME=tkg-$(date +%F-%H-%M)
fi

# Create a service principle and app and store the returned json
RETURNED_SP_APP_JSON=$(az ad sp create-for-rbac --name $AZURE_APP_NAME)

# Setup variables from resulting json
# NOTE(curtis): There are fancy ways to do this as well, but this works
AZURE_CLIENT_ID=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.appId')
AZURE_CLIENT_SECRET=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.password')
AZURE_TENANT_ID=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.tenant')

# Create an SSH key for use
# Create SSH key
mkdir -p keys/
tkg_key_file="./keys/tkg_rsa"
echo "INFO: checking for existing SSH key at $tkg_key_file: "
if [ -f "$tkg_key_file" ]; then
  echo "INFO: skipping ssh key generation"
else
  echo "INFO: generating ssh key at $tkg_key_file"
  ssh-keygen -t rsa -b 4096 -f "$tkg_key_file" -q -N ""
fi

#
# Write resulting variables to params file
#

echo "INFO: writing ssh key to config file"
yq write $TKG_CONFIG -i "AZURE_SSH_PUBLIC_KEY_B64" "$(base64 < "$tkg_key_file" | tr -d '\r\n')"

echo "INFO: azure app name is $AZURE_APP_NAME"
yq write "$PARAMS_YAML" -i "azure.app-name" "$AZURE_APP_NAME"

echo "INFO: azure subscription id is $AZURE_SUBSCRIPTION_ID"
yq write "$PARAMS_YAML" -i "azure.subscription-id" "$AZURE_SUBSCRIPTION_ID"

echo "INFO: azure tenant id is $AZURE_TENANT_ID"
yq write "$PARAMS_YAML" -i "azure.tenant-id" "$AZURE_TENANT_ID"

echo "INFO: azure client id is $AZURE_CLIENT_ID"
yq write "$PARAMS_YAML" -i azure.client-id "$AZURE_CLIENT_ID"

echo "INFO: azure client secret written to $PARAMS_YAML at azure.client-secret"
yq write "$PARAMS_YAML" -i "azure.client-secret" "$AZURE_CLIENT_SECRET"

# done