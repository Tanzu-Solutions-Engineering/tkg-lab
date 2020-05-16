

export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

tkg delete management-cluster -v 5 --config=./k8/config.yaml