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

if [ "$DNS_PROVIDER" = "gcloud-dns" ];
then
  # Using Google Cloud DNS
  export GCLOUD_PROJECT=$(yq e .gcloud.project $PARAMS_YAML)
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
  cp external-dns/values-template-gcloud.yaml generated/$CLUSTER_NAME/external-dns/values.yaml
  yq e -i '.google.project = env(GCLOUD_PROJECT)' generated/$CLUSTER_NAME/external-dns/values.yaml
  yq e -i '.google.serviceAccountSecret = "gcloud-dns-credentials"' generated/$CLUSTER_NAME/external-dns/values.yaml
else
  # Default to AWS Route53
  export AWS_SECRET_KEY=$(yq e .aws.secret-access-key $PARAMS_YAML)
  export AWS_ACCESS_KEY=$(yq e .aws.access-key-id $PARAMS_YAML)
  export AWS_REGION=$(yq e .aws.region $PARAMS_YAML)
  # values.yaml
  cp external-dns/values-template-aws.yaml generated/$CLUSTER_NAME/external-dns/values.yaml
  yq e -i '.aws.credentials.secretKey = env(AWS_SECRET_KEY)' generated/$CLUSTER_NAME/external-dns/values.yaml 
  yq e -i '.aws.credentials.accessKey = env(AWS_ACCESS_KEY)' generated/$CLUSTER_NAME/external-dns/values.yaml 
  yq e -i '.aws.region = env(AWS_REGION)' generated/$CLUSTER_NAME/external-dns/values.yaml 
fi

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install external-dns bitnami/external-dns -n tanzu-system-ingress -f generated/$CLUSTER_NAME/external-dns/values.yaml

#Wait for pod to be ready
while kubectl get po -l app.kubernetes.io/name=external-dns -n tanzu-system-ingress | grep Running ; [ $? -ne 0 ]; do
	echo external-dns is not yet ready
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
