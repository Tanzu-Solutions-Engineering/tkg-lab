#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply ingress-fqdn as arg"
  exit 1
fi
ingress_fqdn=$1
AWS_HOSTED_ZONE=$(yq r $PARAMS_YAML aws.hosted-zone-id)

IAAS=$(yq r $PARAMS_YAML iaas)

if [ $IAAS = 'aws' ];
then
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
  record_type="CNAME"
else
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  record_type="A"
fi
echo "hostname $hostname"

# Grab a fresh template
cp dns/tkg-aws-lab-record-sets-aws.json.template dns/tkg-aws-lab-record-sets-aws.json

# Make the substitutions
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e "s/FQDN/${ingress_fqdn}/g" dns/tkg-aws-lab-record-sets-aws.json
  sed -i '' -e "s/LBHOST/${hostname}/g" dns/tkg-aws-lab-record-sets-aws.json
  sed -i '' -e "s/CNAME/${record_type}/g" dns/tkg-aws-lab-record-sets-aws.json
else
  sed -i -e "s/FQDN/${ingress_fqdn}/g" dns/tkg-aws-lab-record-sets-aws.json
  sed -i -e "s/LBHOST/${hostname}/g" dns/tkg-aws-lab-record-sets-aws.json
  sed -i -e "s/CNAME/${record_type}/g" dns/tkg-aws-lab-record-sets-aws.json
fi

# Execute the change
aws route53 change-resource-record-sets --hosted-zone-id ${AWS_HOSTED_ZONE} --change-batch file://dns/tkg-aws-lab-record-sets-aws.json
rm dns/tkg-aws-lab-record-sets-aws.json
