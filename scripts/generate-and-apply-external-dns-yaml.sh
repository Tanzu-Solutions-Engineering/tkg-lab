#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as arg"
  exit 1
fi

CLUSTER_NAME=$1
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
    --from-file=credentials.json=keys/gcloud-dns-credentials.json \
    -o yaml --dry-run=client | kubectl apply -f-

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-google-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export PROJECT_ID=--google-project=$(yq e .gcloud.project $PARAMS_YAML)
  yq e -i '.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[6] = env(PROJECT_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

elif [ "$DNS_PROVIDER" = "azure-dns" ];
then
  echo "DEBUG: Configuring External DNS for Azure DNS"

  # Expecting that create-dns-zone.sh has been run and ahreasetting up the zone and service principle

  kubectl -n tanzu-system-service-discovery create secret \
    generic azure-config-file \
    --from-file=externaldns-config.json=keys/azure-dns-credentials.json \
    -o yaml --dry-run=client | kubectl apply -f-

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-azure-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  AZURE_DNZ_ZONE_NAME=$(yq e .subdomain $PARAMS_YAML)
  AZURE_ZONE_RESOURCE_GROUP=$(az network dns zone list -o tsv --query "[?name=='$AZURE_DNZ_ZONE_NAME'].resourceGroup")
  export DOMAIN_FILTER=--domain-filter=$AZURE_DNZ_ZONE_NAME
  export AZURE_RESOURCE_GROUP_ARG=--azure-resource-group=$AZURE_ZONE_RESOURCE_GROUP
  yq e -i '.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[6] = env(AZURE_RESOURCE_GROUP_ARG)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

else # Using AWS Route53

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-aws-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export HOSTED_ZONE_ID=--txt-owner-id=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
  yq e -i '.deployment.args[3] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[6] = env(HOSTED_ZONE_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  # Perform special processing to handle Cloudgate use case where session tokens are used
  if [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Using Existing Extension."

    kubectl create secret generic route53-credentials \
      --from-literal=aws_access_key_id=$(yq e .aws.access-key-id $PARAMS_YAML) \
      --from-literal=aws_secret_access_key=$(yq e .aws.secret-access-key $PARAMS_YAML) \
      -n tanzu-system-service-discovery -o yaml --dry-run=client | kubectl apply -f-
  else
    # When using cloudgate, External-DNS should use permissions on the EC2 instance to access Route53 API
    # TODO: Determine if there is a lower privilege than FullAccess that can be used
    aws iam attach-role-policy --role-name nodes.tkg.cloud.vmware.com --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess

    echo "Removing AWS Credentials from Extension"
    # Remove Secret reference from data-values for the external dns so that it will use the instance profile permissions
    yq -i eval 'del(.deployment.env)'  generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  fi

fi

# Retrieve the most recent version number.  There may be more than one version available and we are assuming that the most recent is listed last,
# thus supplying -1 as the index of the array
VERSION=$(tanzu package available list -oyaml | yq eval '.[] | select(.display-name == "external-dns") | .latest-version' -)
tanzu package install external-dns \
    --package-name external-dns.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml \
    --poll-timeout 10m0s
=======
if [[ -f generated/$CLUSTER_NAME/contour/contour-data-values.yaml ]]; then
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
fi
