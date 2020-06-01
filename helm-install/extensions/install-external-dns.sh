#!/bin/bash -e

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

if [ -z "$IAAS" ];then
    IAAS='aws'
fi

helm upgrade --install external-dns-aws ./tkg-extensions-helm-charts/external-dns-aws-0.1.0.tgz \
--set hostedzone=$(yq r $PARAM_FILE aws.dns.hosted-zone-id) \
--set AWS_ACCESS_KEY_ID=$(echo -n $(yq r $PARAM_FILE aws.access-key-id) | base64) \
--set AWS_SECRET_ACCESS_KEY=$(echo -n $(yq r $PARAM_FILE aws.secret-access-key) | base64) \
--set iaas=$IAAS --wait