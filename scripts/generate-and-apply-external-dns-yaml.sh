#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster_name and ingress-fqdn as args"
  exit 1
fi

CLUSTER_NAME=$1
INGRESS_FQDN=$2
DNS_PROVIDER=$(yq r $PARAMS_YAML dns.provider)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/external-dns

if [ "$DNS_PROVIDER" = "gcloud-dns" ];
then
  # Using Google Cloud DNS
  GCLOUD_PROJECT=$(yq r $PARAMS_YAML gcloud.project)
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
  kubectl -n tanzu-system-ingress create secret \
    generic gcloud-dns-credentials \
    --from-file=credentials.json=keys/gcloud-dns-credentials.json
  # values.yaml
  yq read external-dns/values-template-gcloud.yaml > generated/$CLUSTER_NAME/external-dns/values.yaml
  yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "google.project" $GCLOUD_PROJECT
  yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "google.serviceAccountSecret" "gcloud-dns-credentials"
else
  # Default to AWS Route53
  AWS_SECRET_KEY=$(yq r $PARAMS_YAML aws.secret-access-key)
  AWS_ACCESS_KEY=$(yq r $PARAMS_YAML aws.access-key-id)
  AWS_REGION=$(yq r $PARAMS_YAML aws.region)
  # values.yaml
  yq read external-dns/values-template-aws.yaml > generated/$CLUSTER_NAME/external-dns/values.yaml
  yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.credentials.secretKey" $AWS_SECRET_KEY
  yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.credentials.accessKey" $AWS_ACCESS_KEY
  yq write generated/$CLUSTER_NAME/external-dns/values.yaml -i "aws.region" $AWS_REGION
fi

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install external-dns bitnami/external-dns -n tanzu-system-ingress -f generated/$CLUSTER_NAME/external-dns/values.yaml

#Wait for pod to be ready
while kubectl get po -l app.kubernetes.io/name=external-dns -n tanzu-system-ingress | grep Running ; [ $? -ne 0 ]; do
	echo external-dns is not yet ready
	sleep 5s
done

# Now update the contour extension to include external dns annotation
yq write -d0 generated/$CLUSTER_NAME/contour/contour-data-values.yaml -i tkg_lab.ingress_fqdn "$INGRESS_FQDN."

# Add in the document seperator that yq removes
if [ `uname -s` = 'Darwin' ];
then
  sed -i '' '3i\
  ---\
  ' generated/$CLUSTER_NAME/contour/contour-data-values.yaml
else
  sed -i -e '3i\---\' generated/$CLUSTER_NAME/contour/contour-data-values.yaml
fi

# Update contour secret with custom configuration for ingress
kubectl create secret generic contour-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/contour/contour-data-values.yaml -n tanzu-system-ingress -o yaml --dry-run=client | kubectl apply -f-

# Generate the modified contour extension
ytt \
  -f tkg-extensions/extensions/ingress/contour/contour-extension.yaml \
  -f tkg-extensions-mods-examples/ingress/contour/contour-extension-overlay.yaml \
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
