#!/bin/bash -e

export AWS_AMI_ID=$(yq r $PARAM_FILE aws.AWS_AMI_ID)
export AWS_NODE_AZ=$(yq r $PARAM_FILE aws.AWS_NODE_AZ)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAM_FILE aws.secret-access-key)
export AWS_ACCESS_KEY_ID=$(yq r $PARAM_FILE aws.access-key-id)
export AWS_CREDENTIALS=$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)
export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r)
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r)
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

tkg init --infrastructure=aws --name=$(yq r $PARAM_FILE mgmtCluster.name) --plan=dev -v 5 --config=./k8/config.yaml
# default storage class
kubectl apply -f ./k8/default-storage-class.yaml
