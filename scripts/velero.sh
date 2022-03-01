#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as arg"
  exit 1
fi

echo "Beginning Velero install..."

CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

VELERO_BUCKET=$(yq e .velero.bucket $PARAMS_YAML)
IAAS=$(yq e .iaas $PARAMS_YAML)

VELERO_IMAGE_REPO=projects.registry.vmware.com
VELERO_VERSION=v1.7.0_vmware.1
VELERO_PLUGIN_FOR_VSPHERE_VERSION=v1.3.0_vmware.1
VELERO_PLUGIN_FOR_AWS_VERSION=v1.3.0_vmware.1
VELERO_PLUGIN_FOR_AZURE_VERSION=v1.3.0_vmware.1

mkdir -p generated/$CLUSTER_NAME/velero


if [ "$IAAS" = "vsphere" ];
then

  MINIO_URL=http://$(yq e .minio.server-fqdn $PARAMS_YAML):9000

  ACCESS_KEY=$(yq e .minio.root-user $PARAMS_YAML)
  SECRET_KEY=$(yq e .minio.root-password $PARAMS_YAML)

  cat > generated/$CLUSTER_NAME/velero/credentials-velero << EOF
[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
EOF

  # this condition uses the velero-plugin-for-vsphere which is special case.
  kubectl create ns velero --dry-run=client --output yaml | kubectl apply -f -

  # Create config map to indicate where vsphere credentials are stored
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: velero
  name: velero-vsphere-plugin-config
data:
  cluster_flavor: VANILLA
  vsphere_secret_name: vsphere-config-secret
  vsphere_secret_namespace: kube-system
EOF

  velero install \
      --image=$VELERO_IMAGE_REPO/tkg/velero/velero:$VELERO_VERSION \
      --provider aws \
      --plugins=$VELERO_IMAGE_REPO/tkg/velero/velero-plugin-for-aws:$VELERO_PLUGIN_FOR_AWS_VERSION,$VELERO_IMAGE_REPO/tkg/velero/velero-plugin-for-vsphere:$VELERO_PLUGIN_FOR_VSPHERE_VERSION \
      --bucket $VELERO_BUCKET \
      --secret-file generated/$CLUSTER_NAME/velero/credentials-velero \
      --backup-location-config region=default,s3ForcePathStyle="true",s3Url=$MINIO_URL \
      --snapshot-location-config region=default

elif [ "$IAAS" = "azure" ]; then

  VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)
  AZURE_LOCATION=$(yq e .azure.location $PARAMS_YAML)
  AZURE_APP_NAME=$(yq e .azure.app-name $PARAMS_YAML)
  AZURE_SUBSCRIPTION_ID=$(yq e .azure.subscription-id $PARAMS_YAML)
  AZURE_TENANT_ID=$(yq e .azure.tenant-id $PARAMS_YAML)
  AZURE_CLIENT_ID=$(yq e .azure.client-id $PARAMS_YAML)
  AZURE_CLIENT_SECRET=$(yq e .azure.client-secret $PARAMS_YAML)
  AZURE_CLOUD_NAME=$(yq e .azure.environment $PARAMS_YAML)

  AZURE_BACKUP_RESOURCE_GROUP=$CLUSTER_NAME
  AZURE_STORAGE_ACCOUNT_ID=tkglabbackups
  BLOB_CONTAINER=velero-$CLUSTER_NAME

  # validate existance of storage account
  if [ -z "`az storage account list -o tsv --query "[?name=='$AZURE_STORAGE_ACCOUNT_ID']"`" ]; then
    # storage account doesn't exist, so create it
    echo "Creating storage account for velero: $AZURE_STORAGE_ACCOUNT_ID"
    az storage account create \
      --name $AZURE_STORAGE_ACCOUNT_ID \
      --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
      --sku Standard_GRS \
      --encryption-services blob \
      --https-only true \
      --kind BlobStorage \
      --access-tier Hot
  else
    echo "Storage account for velero already exists: $AZURE_STORAGE_ACCOUNT_ID"
  fi

  # validate existance of container
  if [ -z "`az storage container list --account-name $AZURE_STORAGE_ACCOUNT_ID -o tsv --query "[?name=='$BLOB_CONTAINER']"`" ]; then
    # blob container doesn't exist, so create it
    echo "Creating blob container for velero: $BLOB_CONTAINER"
    az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID
  else
    echo "Blob container for velero already exists: $BLOB_CONTAINER"
  fi

  cat << EOF  > generated/$CLUSTER_NAME/velero/credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${AZURE_BACKUP_RESOURCE_GROUP}
AZURE_CLOUD_NAME=${AZURE_CLOUD_NAME}
EOF

  velero install \
      --image=$VELERO_IMAGE_REPO/tkg/velero/velero:$VELERO_VERSION \
      --provider azure \
      --plugins $VELERO_IMAGE_REPO/tkg/velero/velero-plugin-for-microsoft-azure:$VELERO_PLUGIN_FOR_AZURE_VERSION \
      --bucket $BLOB_CONTAINER \
      --secret-file generated/$CLUSTER_NAME/velero/credentials-velero \
      --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID \

elif [ "$IAAS" = "aws" ]; then


  echo aws
  AWS_REGION=$(yq e .aws.region $PARAMS_YAML)

  if [ -z "$AWS_SESSION_TOKEN" ]; then
  # this condition is for AWS without CloudGate

    ACCESS_KEY=$(yq e .aws.access-key-id $PARAMS_YAML)
    SECRET_KEY=$(yq e .aws.secret-access-key $PARAMS_YAML)

    cat > generated/$CLUSTER_NAME/velero/credentials-velero << EOF
[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
EOF

    # this condition is for AWS without CloudGate or for Azure (yes, azure still uses the plugin for aws)
    # note for Azure users, it will only work if you have non-CloudGate AWS credentials for S3
    velero install \
        --image=$VELERO_IMAGE_REPO/tkg/velero/velero:$VELERO_VERSION \
        --provider aws \
        --plugins $VELERO_IMAGE_REPO/tkg/velero/velero-plugin-for-aws:$VELERO_PLUGIN_FOR_AWS_VERSION \
        --bucket $VELERO_BUCKET \
        --backup-location-config region=$AWS_REGION \
        --snapshot-location-config region=$AWS_REGION \
        --secret-file generated/$CLUSTER_NAME/velero/credentials-velero
  else

    # this condition is for AWS with with CloudGate

    echo "Using IAM Profile for S3 Access"
    velero install \
        --image=$VELERO_IMAGE_REPO/tkg/velero/velero:$VELERO_VERSION \
        --provider aws \
        --plugins $VELERO_IMAGE_REPO/tkg/velero/velero-plugin-for-aws:$VELERO_PLUGIN_FOR_AWS_VERSION \
        --bucket $VELERO_BUCKET \
        --backup-location-config region=$AWS_REGION \
        --snapshot-location-config region=$AWS_REGION \
        --no-secret
  fi
fi

# Wait for it to be ready
while kubectl get po -n velero | grep Running ; [ $? -ne 0 ]; do
	echo Velero is not yet ready
	sleep 5
done

# Setup the backup schedule
if [ "$IAAS" = "vsphere" ];
then
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *" \
    --volume-snapshot-locations default
else
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *"
fi
