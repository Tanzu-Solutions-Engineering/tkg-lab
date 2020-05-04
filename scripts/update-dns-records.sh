#!/bin/bash -e
: ${BASE_DOMAIN?"Need to set BASE_DOMAIN environment variable"}
: ${LAB_NAME?"Need to set LAB_NAME environment variable"}


if [ ! $# -eq 1 ]; then
  echo "Must supply sub_domain as arg"
  exit 1
fi

sub_domain=$1
hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'.`
record_type="CNAME"
if [ $hostname = '.' ]; then
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  record_type="A"
fi

yq write -d0 dns/tkg-lab-record-sets.yml -i "name" ${LAB_NAME}.${BASE_DOMAIN}.
yq write -d1 dns/tkg-lab-record-sets.yml -i "name" ${LAB_NAME}.${BASE_DOMAIN}.

if [ $sub_domain = '*.mgmt' ]; then
  yq write -d2 dns/tkg-lab-record-sets.yml -i "name" *.mgmt.${LAB_NAME}.${BASE_DOMAIN}.
  yq write -d2 dns/tkg-lab-record-sets.yml -i "rrdatas[0]" $hostname
  yq write -d2 dns/tkg-lab-record-sets.yml -i "type" $record_type
fi
if [ $sub_domain = '*.wlc-1' ]; then
  yq write -d3 dns/tkg-lab-record-sets.yml -i "name" *.wlc-1.${LAB_NAME}.${BASE_DOMAIN}.
  yq write -d3 dns/tkg-lab-record-sets.yml -i "rrdatas[0]" $hostname
  yq write -d3 dns/tkg-lab-record-sets.yml -i "type" $record_type
fi
gcloud dns record-sets import dns/tkg-lab-record-sets.yml \
  --zone $LAB_NAME \
  --delete-all-existing
