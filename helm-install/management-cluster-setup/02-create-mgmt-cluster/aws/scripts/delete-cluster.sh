
export AWS_ACCESS_KEY_ID=$(yq r $PARAM_FILE aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAM_FILE aws.secret-access-key)
export AWS_REGION=$(yq r $PARAM_FILE aws.region)
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)
tkg delete management-cluster -v 5 --config=./k8/config.yaml