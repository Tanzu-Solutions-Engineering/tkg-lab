#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

if [ "$TKG_CONFIG" = "" ]; then
  TKG_CONFIG=~/.tkg/config.yaml
fi

# List of vars that need to be added to the $TKG_CONFIG. WilL be taken from
# the params.yml file.
AZURE_VAR_LIST="ENVIRONMENT 
TENANT_ID 
SUBSCRIPTION_ID 
CLIENT_ID
CLIENT_SECRET 
LOCATION 
CONTROL_PLANE_MACHINE_TYPE
NODE_MACHINE_TYPE"

# Read variables from the params file and write to the tkg config
AZURE_CLIENT_SECRET=$(yq r $TKG_CONFIG AZURE_CLIENT_SECRET)
if [ -z "$AZURE_CLIENT_SECRET" ]; then
  echo "Azure client secret NOT found in config, setting up $TKG_CONFIG with \
  Azure variables from params.yaml."

  for AZURE_VAR in $AZURE_VAR_LIST; do
    
    echo "Processing $AZURE_VAR from list..."

    # Make lowercase and convert _ to - to find in params file
    CONVERTED_AZURE_VAR=`echo $AZURE_VAR | awk '{print tolower($0)}'`
    CONVERTED_AZURE_VAR=`echo $CONVERTED_AZURE_VAR | awk '{gsub("_","-",$0); print $0}'`
    
    # Find the entry in the params file to write the TKG_CONFIG
    entry=$(yq r "$PARAMS_YAML" azure."$CONVERTED_AZURE_VAR")
    if [ -z "$entry" ]; then
      echo "ERROR: missing parameter azure.$CONVERTED_AZURE_VAR, exiting"
      exit 1
    fi

    # Write the entry prefixing variables with "AZURE_"
    yq write $TKG_CONFIG -i "AZURE_$AZURE_VAR" "$entry"
  done
fi

MANAGEMENT_CLUSTER_NAME=$(yq r "$PARAMS_YAML" management-cluster.name)

tkg init --infrastructure=azure --name="$MANAGEMENT_CLUSTER_NAME" \
  --plan=dev -v 6
