#!/bin/bash -e
: ${AWS_ACCESS_KEY_ID?"Need to set AWS_ACCESS_KEY_ID environment variable"}
: ${AWS_SECRET_ACCESS_KEY?"Need to set AWS_SECRET_ACCESS_KEY environment variable"}
: ${AWS_REGION?"Need to set AWS_REGION environment variable"}

export AWS_CREDENTIALS=$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)

export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r)
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r)
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

tkg init --infrastructure=aws --name=tkg-mgmt-aws --plan=dev -v 6
