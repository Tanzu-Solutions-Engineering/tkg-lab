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

kubectl apply -f tkg-extensions/extensions/service-discovery/external-dns/namespace-role.yaml

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

  add_yaml_doc_seperator generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

else # Using AWS Route53

  cp tkg-extensions/extensions/service-discovery/external-dns/external-dns-data-values-aws-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export HOSTED_ZONE_ID=--txt-owner-id=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
  yq e -i '.externalDns.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.externalDns.deployment.args[9] = env(HOSTED_ZONE_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  add_yaml_doc_seperator generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  kubectl create secret generic route53-credentials \
    --from-literal=aws_access_key_id=$(yq e .aws.access-key-id $PARAMS_YAML) \
    --from-literal=aws_secret_access_key=$(yq e .aws.secret-access-key $PARAMS_YAML) \
    -n tanzu-system-service-discovery -o yaml --dry-run=client | kubectl apply -f-
fi

# Using the following "apply" syntax to allow for script to be rerun
kubectl create secret generic external-dns-data-values \
  --from-file=values.yaml=generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml \
  -n tanzu-system-service-discovery -o yaml --dry-run=client | kubectl apply -f-

kubectl apply -f tkg-extensions/extensions/service-discovery/external-dns/external-dns-extension.yaml

while kubectl get app external-dns -n tanzu-system-service-discovery | grep external-dns | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
  echo External-Dns extension is not yet ready
  sleep 5s
done



# Now update the contour extension to include external dns annotation
yq e -i '.tkg_lab.ingress_fqdn = strenv(INGRESS_FQDN)' generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Add in the document seperator that yq removes
add_yaml_doc_seperator generated/$CLUSTER_NAME/contour/contour-data-values.yaml

# Update contour secret with custom configuration for ingress
kubectl create secret generic contour-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/contour/contour-data-values.yaml -n tanzu-system-ingress -o yaml --dry-run=client | kubectl apply -f-

# Generate the modified contour extension
ytt \
  -f tkg-extensions/extensions/ingress/contour/contour-extension.yaml \
  -f tkg-extensions-mods-examples/ingress/contour/contour-extension-overlay.yaml \
  --ignore-unknown-comments \
  > generated/$CLUSTER_NAME/contour/contour-extension.yaml

# Create configmap with the overlay
kubectl create configmap contour-overlay -n tanzu-system-ingress -o yaml --dry-run=client \
  --from-file=contour-overlay.yaml=tkg-extensions-mods-examples/ingress/contour/contour-overlay.yaml | kubectl apply -f-

# Update Contour using modifified Extension
kubectl apply -f generated/$CLUSTER_NAME/contour/contour-extension.yaml

# Wait until reconcile succeeds
while kubectl get app contour -n tanzu-system-ingress | grep contour | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
  echo contour extension is not yet ready
  sleep 5
done
