#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name and ingress-fqdn as args"
  exit 1
fi

CLUSTER_NAME=$1
INGRESS_FQDN=$2

AWS_SECRET_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
AWS_ACCESS_KEY=$(yq r $PARAMS_YAML aws.access-key-id)
AWS_REGION=$(yq r $PARAMS_YAML aws.region)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/external-dns

# values.yaml
yq read external-dns/values-template.yaml > generated/$CLUSTER_NAME/external-dns/values.yaml
yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.credentials.secretKey" $AWS_SECRET_KEY
yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.credentials.accessKey" $AWS_ACCESS_KEY
yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.region" AWS_REGION

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install external-dns bitnami/external-dns -n tanzu-system-ingress -f generated/$CLUSTER_NAME/external-dns/values.yaml

#Wait for pod to be ready
while kubectl get po -l app.kubernetes.io/name=external-dns -n tanzu-system-ingress | grep Running ; [ $? -ne 0 ]; do
	echo external-dns is not yet ready
	sleep 5s
done

kubectl annotate service envoy "external-dns.alpha.kubernetes.io/hostname=$INGRESS_FQDN." -n tanzu-system-ingress --overwrite
