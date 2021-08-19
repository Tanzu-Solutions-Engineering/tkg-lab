#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name and ingress-fqdn as args"
  exit 1
fi

CLUSTER_NAME=$1
export INGRESS_FQDN=$2
DNS_PROVIDER=$(yq e .dns.provider $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/external-dns

kubectl create namespace tanzu-system-service-discovery --dry-run=client --output yaml | kubectl apply -f -

if [ "$DNS_PROVIDER" = "gcloud-dns" ];
then
  # Using Google Cloud DNS
  # Create GCloud Service Account
  GCP_SERVICE_ACCOUNT=`gcloud iam service-accounts list | grep external-dns`
  if [ -z "$GCP_SERVICE_ACCOUNT" ]
  then
    gcloud iam service-accounts create external-dns \
      --display-name "Service account for ExternalDNS on GCP"
    gcloud projects add-iam-policy-binding $GCLOUD_PROJECT \
      --role='roles/dns.admin' \
      --member='serviceAccount:external-dns@'$GCLOUD_PROJECT'.iam.gserviceaccount.com'
      gcloud iam service-accounts keys create keys/gcloud-dns-credentials.json \
        --iam-account 'external-dns@'$GCLOUD_PROJECT'.iam.gserviceaccount.com'
  fi
  kubectl -n tanzu-system-service-discovery create secret \
    generic gcloud-dns-credentials \
    --from-file=credentials.json=keys/gcloud-dns-credentials.json

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-google-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export PROJECT_ID=--google-project=$(yq e .gcloud.project $PARAMS_YAML)
  yq e -i '.externalDns.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.externalDns.deployment.args[6] = env(PROJECT_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

else # Using AWS Route53

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-aws-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export HOSTED_ZONE_ID=--txt-owner-id=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
  yq e -i '.externalDns.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.externalDns.deployment.args[9] = env(HOSTED_ZONE_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  # Perform special processing to handle Cloudgate use case where session tokens are used 
  if [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Using Existing Extension."
  else
    echo "removing AWS Credentials from Extension"
    # Remove Secret reference from data-values for the external dns extension. 
    sed -n -e :a -e '1,12!{P;N;D;};N;ba' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml > generated/$CLUSTER_NAME/external-dns/external-dns-data-values-fixed.yaml
    rm generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
    mv generated/$CLUSTER_NAME/external-dns/external-dns-data-values-fixed.yaml generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  fi

  kubectl create secret generic route53-credentials \
    --from-literal=aws_access_key_id=$(yq e .aws.access-key-id $PARAMS_YAML) \
    --from-literal=aws_secret_access_key=$(yq e .aws.secret-access-key $PARAMS_YAML) \
    -n tanzu-system-service-discovery -o yaml --dry-run=client | kubectl apply -f-
fi

tanzu package install external-dns \
    --package-name external-dns.tanzu.vmware.com \
    --version 0.8.0+vmware.1-tkg.1-rc.2 \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

# Now update the contour extension to include external dns annotation
yq e -i '.tkg_lab.ingress_fqdn = strenv(INGRESS_FQDN)' generated/$CLUSTER_NAME/contour/contour-data-values.yaml

kubectl create secret generic contour-overlay -n tanzu-kapp -o yaml --dry-run=client --from-file=tkg-extensions-mods-examples/ingress/contour/contour-overlay.yaml | kubectl apply -f-

# must annotate the packageinstall referring to the secret above
kubectl annotate PackageInstall contour \
	-n tanzu-kapp \
	ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=contour-overlay \
	--overwrite=true

tanzu package installed update contour \
    --namespace tanzu-kapp \
    --version 1.17.1+vmware.1-tkg.1-rc.2 \
    --values-file generated/$CLUSTER_NAME/contour/contour-data-values.yaml

