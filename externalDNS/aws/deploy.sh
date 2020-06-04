
if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1
HOSTED_ZONE_ID=$(yq r params.yaml aws.hosted-zone-id)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/externalDNS/

IAAS=$(yq r params.yaml iaas)
AWS_ACCESS_KEY_ID=$(yq r params.yaml access-key-id)
AWS_SECRET_ACCESS_KEY=$(yq r params.yaml secret-access-key)

if [ $IAAS = 'vsphere' ];
then
  echo 'vsphere'
  kubectl create secret generic external-dns-iam-keys --from-literal=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --from-literal=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
  cp externalDNS/aws/deployment-vsphere.yaml generated/$CLUSTER_NAME/externalDNS/deployment.yaml
else
  cp externalDNS/aws/deployment-aws.yaml generated/$CLUSTER_NAME/externalDNS/deployment.yaml
fi

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e 's/$HOSTED_ZONE_ID/'$HOSTED_ZONE_ID'/g' generated/$CLUSTER_NAME/externalDNS/deployment.yaml
else
  sed -i -e 's/$HOSTED_ZONE_ID/'$HOSTED_ZONE_ID'/g' generated/$CLUSTER_NAME/externalDNS/deployment.yaml
fi

kubectl apply -f generated/$CLUSTER_NAME/externalDNS/deployment.yaml