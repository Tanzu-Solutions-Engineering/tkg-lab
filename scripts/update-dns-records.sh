  #!/bin/bash -e
: ${BASE_DOMAIN?"Need to set BASE_DOMAIN environment variable"}

if [ ! $# -eq 1 ]; then
  echo "Must supply sub_domain as arg"
  exit 1
fi

sub_domain=$1
hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`

yq write -d0 dns/tkg-aws-lab-record-sets.yml -i "name" tkg-aws-lab.$BASE_DOMAIN.
yq write -d1 dns/tkg-aws-lab-record-sets.yml -i "name" tkg-aws-lab.$BASE_DOMAIN.

if [ $sub_domain = '*.mgmt' ]; then
  yq write -d2 dns/tkg-aws-lab-record-sets.yml -i "name" *.mgmt.tkg-aws-lab.$BASE_DOMAIN.live.
  yq write -d2 dns/tkg-aws-lab-record-sets.yml -i "rrdatas[0]" $hostname.
fi
if [ $sub_domain = '*.wlc-1' ]; then
  yq write -d3 dns/tkg-aws-lab-record-sets.yml -i "name" *.wlc-1.tkg-aws-lab.$BASE_DOMAIN.
  yq write -d3 dns/tkg-aws-lab-record-sets.yml -i "rrdatas[0]" $hostname.
fi

gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing