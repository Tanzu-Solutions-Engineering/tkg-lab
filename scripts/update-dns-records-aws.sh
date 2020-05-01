#!/bin/bash -e
: ${AWS_HOSTED_ZONE?"Need to set AWS_HOSTED_ZONE environment variable"}
: ${BASE_DOMAIN?"Need to set BASE_DOMAIN environment variable"}

if [ ! $# -eq 1 ]; then
  echo "Must supply sub_domain as arg"
  exit 1
fi

sub_domain=$1
hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`

# Grab a fresh template
cp dns/tkg-aws-lab-record-sets-aws.json.template dns/tkg-aws-lab-record-sets-aws.json

# Make the substitutions
sed -i -e "s/BASE_DOMAIN/${BASE_DOMAIN}/g" dns/tkg-aws-lab-record-sets-aws.json
sed -i -e "s/SUBDOMAIN/${sub_domain}/g" dns/tkg-aws-lab-record-sets-aws.json
sed -i -e "s/LBHOST/${hostname}/g" dns/tkg-aws-lab-record-sets-aws.json

# Execute the change
aws route53 change-resource-record-sets --hosted-zone-id ${AWS_HOSTED_ZONE} --change-batch file://dns/tkg-aws-lab-record-sets-aws.json
