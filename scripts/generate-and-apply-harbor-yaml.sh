#! /bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply Mgmt and Shared Services cluster name as args"
  exit 1
fi
MGMT_CLUSTER_NAME=$1
SHAREDSVC_CLUSTER_NAME=$2

# Identifying Shared Services Cluster at TKG level
kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME
kubectl label cluster.cluster.x-k8s.io/$SHAREDSVC_CLUSTER_NAME cluster-role.tkg.tanzu.vmware.com/tanzu-services="" --overwrite=true
tanzu login --server $MGMT_CLUSTER_NAME
tanzu cluster list --include-management-cluster

# Install Harbor in Shared Services Cluster
kubectl config use-context $SHAREDSVC_CLUSTER_NAME-admin@$SHAREDSVC_CLUSTER_NAME

echo "Beginning Harbor install..."
# Since this is installed after Contour, then cert-manager, tmc-extension-manager and kapp-controller should be already deployed in the cluster,
# so we don't need to install those.

export HARBOR_CN=$(yq e .harbor.harbor-cn $PARAMS_YAML)
# NOTARY_CN=$(yq r $PARAMS_YAML harbor.notary-cn) - TKG 1.2 Extensions force the Notary FQDN to be "notary."+HARBOR_CN
export NOTARY_CN="notary."$HARBOR_CN

mkdir -p generated/$SHAREDSVC_CLUSTER_NAME/harbor

# Create a namespace for the Harbor service on the shared services cluster.
kubectl apply -f tkg-extensions/extensions/registry/harbor/namespace-role.yaml

# Create certificate 02-certs.yaml
cp tkg-extensions-mods-examples/registry/harbor/02-certs.yaml generated/$SHAREDSVC_CLUSTER_NAME/harbor/02-certs.yaml
yq e -i ".spec.commonName = env(HARBOR_CN)" generated/$SHAREDSVC_CLUSTER_NAME/harbor/02-certs.yaml 
yq e -i ".spec.dnsNames[0] = env(HARBOR_CN)" generated/$SHAREDSVC_CLUSTER_NAME/harbor/02-certs.yaml
yq e -i ".spec.dnsNames[1] = env(NOTARY_CN)" generated/$SHAREDSVC_CLUSTER_NAME/harbor/02-certs.yaml
kubectl apply -f generated/$SHAREDSVC_CLUSTER_NAME/harbor/02-certs.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-registry harbor-cert | grep True ; [ $? -ne 0 ]; do
	echo Harbor certificate is not yet ready
	sleep 5s
done
# Read Harbor certificate details and store in files
export HARBOR_CERT_CRT=$(kubectl get secret harbor-cert-tls -n tanzu-system-registry -o=jsonpath={.data."tls\.crt"} | base64 --decode)
export HARBOR_CERT_KEY=$(kubectl get secret harbor-cert-tls -n tanzu-system-registry -o=jsonpath={.data."tls\.key"} | base64 --decode)
export HARBOR_CERT_CA=$(cat keys/letsencrypt-ca.pem)

# Prepare Harbor custom configuration
cp tkg-extensions/extensions/registry/harbor/harbor-data-values.yaml.example generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
# Run script to generate passwords
bash tkg-extensions/extensions/registry/harbor/generate-passwords.sh generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
# Specify settings in harbor-data-values.yaml

export CLAIR_ENABLED=false
export HARBOR_ADMIN_PASSWORD=$(yq e ".harbor.admin-password" $PARAMS_YAML)
yq e -i ".hostname = env(HARBOR_CN)" generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.harborAdminPassword = "Harbor12345"' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.clair.enabled = env(CLAIR_ENABLED)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."tls.crt" = strenv(HARBOR_CERT_CRT)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."tls.key" = strenv(HARBOR_CERT_KEY)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."ca.crt" = strenv(HARBOR_CERT_CA)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml 
yq e -i '.ca = "letsencrypt"' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
# Enhance PVC to 30GB for TBS use cases. Comment this row if 10GB is enough for you
yq e -i '.persistence.persistentVolumeClaim.registry.size = "30Gi"' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.harborAdminPassword = env(HARBOR_ADMIN_PASSWORD)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# Check for Blob storage type
# TODO: COME BACK AND CONERT THIS TO YQ 4
HARBOR_BLOB_STORAGE_TYPE=$(yq e .harbor.blob-storage.type $PARAMS_YAML)
if [ "s3" == "$HARBOR_BLOB_STORAGE_TYPE" ]; then
  yq d generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.persistentVolumeClaim"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.type" "s3"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.regionendpoint" "$(yq r $PARAMS_YAML harbor.blob-storage.regionendpoint)"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.region" "$(yq r $PARAMS_YAML harbor.blob-storage.region)"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.accesskey" "$(yq r $PARAMS_YAML harbor.blob-storage.access-key-id)"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.secretkey" "$(yq r $PARAMS_YAML harbor.blob-storage.secret-access-key)"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.bucket" "$(yq r $PARAMS_YAML harbor.blob-storage.bucket)"
  yq write generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml -i "persistence.imageChartStorage.s3.secure" "$(yq r $PARAMS_YAML harbor.blob-storage.secure)"
fi

# Add in the document seperator that yq removes
add_yaml_doc_seperator generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# Create a Kubernetes secret named harbor-data-values with the values that you set in harbor-data-values.yaml.
# Using the following "apply" syntax to allow for re-run
kubectl create secret generic harbor-data-values -n tanzu-system-registry -o yaml --dry-run=client \
  --from-file=values.yaml=generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml | kubectl apply -f -

# Put the Let's Encrypt CA certificate into a configmap to add to trusted certifcates
ytt -f overlay/trust-certificate/configmap.yaml -f overlay/trust-certificate/values.yaml --ignore-unknown-comments \
  --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
  --data-value ca=letsencrypt | kubectl apply -f - -n tanzu-system-registry

# Add overlay to use let's encrypt cluster issuer and trust Let's Encrypt
kubectl create configmap harbor-overlay -n tanzu-system-registry -o yaml --dry-run=client \
  --from-file=overlay-s3-pvc-fix.yaml=tkg-extensions-mods-examples/registry/harbor/overlay-s3-pvc-fix.yaml \
  --from-file=trust-letsencrypt.yaml=overlay/trust-certificate/overlay.yaml | kubectl apply -f-

# Generate the modified harbor extension
ytt \
  -f tkg-extensions/extensions/registry/harbor/harbor-extension.yaml \
  -f tkg-extensions-mods-examples/registry/harbor/harbor-extension-overlay.yaml \
  > generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-extension.yaml

# Update Harbor using modifified Extension
kubectl apply -f generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-extension.yaml

while kubectl get app harbor -n tanzu-system-registry | grep harbor | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo Harbor extension is not yet ready
	sleep 5s
done

# At this point the Harbor Extension is installed and we can access Harbor via its UI as well as push images to it

echo "Okta OIDC Configurtion Values..."
echo "Auth Mode: OIDC"
echo "OIDC Provider Name: Okta"
echo "OIDC Endpoint: https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)/oauth2/default"
echo "OIDC Client ID: $(yq e .okta.harbor-app-client-id $PARAMS_YAML)"
echo "OIDC Client Secret: $(yq e .okta.harbor-app-client-secret $PARAMS_YAML)"
echo "Group Claim Name: groups"
echo "OIDC Scope: openid,profile,email,groups,offline_access"
echo "Verify Certificate: checked"
