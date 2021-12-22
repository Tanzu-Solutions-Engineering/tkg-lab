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
# Since this is installed after Contour, then cert-manager and TMC Extensions Manager should be already deployed in the cluster, so we don't need to install those.

export HARBOR_CN=$(yq e .harbor.harbor-cn $PARAMS_YAML)

export NOTARY_CN="notary."$HARBOR_CN

mkdir -p generated/$SHAREDSVC_CLUSTER_NAME/harbor

# Create a namespace for the Harbor service on the shared services cluster.
kubectl create namespace tanzu-system-registry --dry-run=client --output yaml | kubectl apply -f -

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
image_url=$(kubectl -n tanzu-package-repo-global get packages harbor.tanzu.vmware.com.2.2.3+vmware.1-tkg.1-rc.3 -o jsonpath='{.spec.template.spec.fetch[0].imgpkgBundle.image}')
imgpkg pull -b $image_url -o /tmp/harbor-package-2.2.3
cp /tmp/harbor-package-2.2.3/config/values.yaml generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# Run script to generate passwords
bash /tmp/harbor-package-2.2.3/config/scripts/generate-passwords.sh generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# Specify settings in harbor-data-values.yaml
export HARBOR_ADMIN_PASSWORD=$(yq e ".harbor.admin-password" $PARAMS_YAML)
yq e -i ".hostname = env(HARBOR_CN)" generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."tls.crt" = strenv(HARBOR_CERT_CRT)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."tls.key" = strenv(HARBOR_CERT_KEY)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.tlsCertificate."ca.crt" = strenv(HARBOR_CERT_CA)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
# Enhance PVC to 30GB for TBS use cases. Comment this row if 10GB is enough for you
yq e -i '.persistence.persistentVolumeClaim.registry.size = "30Gi"' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml
yq e -i '.harborAdminPassword = env(HARBOR_ADMIN_PASSWORD)' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# # Remove all comments
yq -i eval '... comments=""' generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

# Create Harbor using modifified Extension
VERSION=$(tanzu package available list harbor.tanzu.vmware.com -oyaml | yq eval ".[0].version" -)
tanzu package install harbor \
    --package-name harbor.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$SHAREDSVC_CLUSTER_NAME/harbor/harbor-data-values.yaml

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
