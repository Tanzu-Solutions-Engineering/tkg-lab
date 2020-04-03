# usage: ./02-deploy-mgmt-cluster.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY

export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export AWS_REGION=us-east-2

aws iam delete-access-key --access-key-id $(aws iam list-access-keys --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json | jq .AccessKeyMetadata[0].AccessKeyId -r) --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io
export AWS_CREDENTIALS=$(aws iam create-access-key --user-name bootstrapper.cluster-api-provider-aws.sigs.k8s.io --output json)

export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq .AccessKey.AccessKeyId -r)
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq .AccessKey.SecretAccessKey -r)
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

# us-east-2 AMI
export AWS_AMI_ID=ami-0d47a0c1ceaca063d

tkg init --infrastructure=aws --name=tkg-mgmt-aws --plan=dev --config config.yaml -v 6
