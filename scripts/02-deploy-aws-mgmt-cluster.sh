#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

# Here we are looking to get the encoded credentials of a lower privileged access key that was created by our boostrap.  If you have created too many keys, then you 
# may face an issue where you can no longer create keys.  So here are some commands that are helpful to diagnose and delete old keys
# Identify existing access keys: aws iam list-access-keys --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json
# Delete access key: aws iam delete-access-key --access-key-id=KEY_FROM_ABOVE --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io

if [ "$TKG_CONFIG" = "" ]; then
  TKG_CONFIG=~/.tkg/config.yaml
fi

AWS_B64ENCODED_CREDENTIALS=$(yq r $TKG_CONFIG AWS_B64ENCODED_CREDENTIALS)
if [ -z "$AWS_B64ENCODED_CREDENTIALS" ];then
  echo "Encoded access key credentials not found in config.  Creating a new one and storing in the config."
  export AWS_REGION=$(yq r $PARAMS_YAML aws.region)
  export AWS_ACCESS_KEY_ID=$(yq r $PARAMS_YAML aws.access-key-id)
  export AWS_SECRET_ACCESS_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
  AWS_CREDENTIALS=$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)
  export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r)
  export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r)
  AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)
  yq write $TKG_CONFIG -i "AWS_B64ENCODED_CREDENTIALS" $AWS_B64ENCODED_CREDENTIALS
fi

MANAGEMENT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)

tkg init --infrastructure=aws --name=$MANAGEMENT_CLUSTER_NAME --plan=dev -v 6
