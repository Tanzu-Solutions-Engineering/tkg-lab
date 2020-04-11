# usage: ./01-prep-aws-objects.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY

#export AWS_ACCESS_KEY_ID=$1
#export AWS_SECRET_ACCESS_KEY=$2
#export AWS_REGION=us-east-2

clusterawsadm alpha bootstrap create-stack

mkdir -p keys/
aws ec2 delete-key-pair --key-name tkg-default
aws ec2 create-key-pair --key-name tkg-default --output json | jq .KeyMaterial -r > keys/aws-ssh.pem
