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
  export GCLOUD_PROJECT=$(yq e .gcloud.project $PARAMS_YAML )
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
  yq e -i '.deployment.args[4] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[7] = env(PROJECT_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

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
  yq e -i '.deployment.args[4] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[7] = env(AZURE_RESOURCE_GROUP_ARG)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

else # Using AWS Route53

  cp tkg-extensions-mods-examples/service-discovery/external-dns/external-dns-data-values-aws-with-contour.yaml.example generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

  export DOMAIN_FILTER=--domain-filter=$(yq e .subdomain $PARAMS_YAML)
  export HOSTED_ZONE_ID=--txt-owner-id=$(yq e .aws.hosted-zone-id $PARAMS_YAML)
  yq e -i '.deployment.args[4] = env(DOMAIN_FILTER)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml
  yq e -i '.deployment.args[7] = env(HOSTED_ZONE_ID)' generated/$CLUSTER_NAME/external-dns/external-dns-data-values.yaml

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

# Apply overlay for metrics
kubectl apply -f tkg-extensions-mods-examples/service-discovery/external-dns/metrics-overlay.yaml -n tanzu-kapp
kubectl annotate PackageInstall external-dns -n tanzu-kapp ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=metrics-overlay