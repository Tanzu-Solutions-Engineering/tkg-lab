#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

#
# Setup and preflight checks
#

# Get client id
AZURE_CREDENTIALS_CONFIGURED=false
export AZURE_CLIENT_ID=$(yq e '.azure.client-id // null' "$PARAMS_YAML")
# NOTE: yq returns null string...
if [ "$AZURE_CLIENT_ID" != "null" ]; then
  echo "INFO: client id already configured in $PARAMS_YAML, not setting up azure credentials"
  AZURE_CREDENTIALS_CONFIGURED=true
fi

# Ensure az is configured and working
if ! az account show > /dev/null; then
  echo "ERROR: could not run az account show, please configure az"
  exit 1
fi

# check for jq
if ! command -v jq &> /dev/null
then
    echo "ERROR: this script requires jq, please install it"
    exit 1
fi

#
# Configure
#

if [ "$AZURE_CREDENTIALS_CONFIGURED" == "false" ]; then

  # Get subscription id
  export AZURE_SUBSCRIPTION_ID=$(yq e '.azure.subscription-id // null' "$PARAMS_YAML")
  if [ "$AZURE_SUBSCRIPTION_ID" == "null" ]; then
      export AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
      echo "INFO: AZURE_SUBSCRIPTION_ID is $AZURE_SUBSCRIPTION_ID"
  fi

  # Create an app name - tkg-$date
  export AZURE_APP_NAME=$(yq e '.azure.app-name // null' "$PARAMS_YAML")
  if [ "$AZURE_APP_NAME" == "null" ] || [ -z "$AZURE_APP_NAME" ]; then
    export AZURE_APP_NAME=tkg-$(date +%F-%H-%M)
  fi
  echo "INFO: AZURE_APP_NAME is $AZURE_APP_NAME"

  # Create a service principle and app and store the returned json
  RETURNED_SP_APP_JSON=$(az ad sp create-for-rbac --name $AZURE_APP_NAME)
  echo "INFO: RETURNED_SP_APP_JSON is $RETURNED_SP_APP_JSON"

  # Setup variables from resulting json
  # NOTE(curtis): There are fancy ways to do this as well, but this works
  export AZURE_CLIENT_ID=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.appId')
  export AZURE_CLIENT_SECRET=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.password')
  export AZURE_TENANT_ID=$(echo "$RETURNED_SP_APP_JSON" | jq -r '.tenant')

  # set vars in params file
  echo "INFO: azure app name is $AZURE_APP_NAME"
  yq e -i '.azure.app-name = env(AZURE_APP_NAME)' "$PARAMS_YAML"

  echo "INFO: azure subscription id is $AZURE_SUBSCRIPTION_ID"
  yq e -i '.azure.subscription-id = env(AZURE_SUBSCRIPTION_ID)' "$PARAMS_YAML"

  echo "INFO: azure tenant id is $AZURE_TENANT_ID"
  yq e -i '.azure.tenant-id = env(AZURE_TENANT_ID)' "$PARAMS_YAML"

  echo "INFO: azure client id is $AZURE_CLIENT_ID"
  yq e -i '.azure.client-id = env(AZURE_CLIENT_ID)' "$PARAMS_YAML"

  echo "INFO: azure client secret written to $PARAMS_YAML at azure.client-secret"
  yq e -i '.azure.client-secret = env(AZURE_CLIENT_SECRET)' "$PARAMS_YAML"

fi

# Create an SSH key for use
mkdir -p keys/
TKG_ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
tkg_key_file="./keys/$TKG_ENVIRONMENT_NAME-ssh"
if [ -f "$tkg_key_file" ]; then
  echo "INFO: skipping ssh key generation"
else
  echo "INFO: generating ssh key at $tkg_key_file"
  ssh-keygen -t rsa -b 4096 -f "$tkg_key_file" -q -N ""
fi

# Get cluster name and prepare cluster-config file
export CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export CLUSTER_CONFIG="generated/$CLUSTER_NAME/cluster-config.yaml"
echo "INFO: creating cluster config file"
mkdir -p generated/$CLUSTER_NAME
cp config-templates/azure-mc-config.yaml "$CLUSTER_CONFIG"

echo "INFO: writing ssh key to tanzu cluster config file"
if [ `uname -s` = 'Darwin' ];
then
	export AZURE_SSH_PUBLIC_KEY_B64=$(base64 < "$tkg_key_file".pub | tr -d '\r\n')
else
  export AZURE_SSH_PUBLIC_KEY_B64=$(base64 -w 0 < "$tkg_key_file".pub | tr -d '\r\n')
fi
yq e -i '.AZURE_SSH_PUBLIC_KEY_B64 = env(AZURE_SSH_PUBLIC_KEY_B64)' "$CLUSTER_CONFIG"

# done
