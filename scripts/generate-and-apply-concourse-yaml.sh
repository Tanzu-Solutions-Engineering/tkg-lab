#!/bin/bash -e

CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
export CONCOURSE_FQDN=$(yq e .concourse.fqdn $PARAMS_YAML)
export CONCOURSE_URL=https://$CONCOURSE_FQDN
CONCOURSE_NAMESPACE=$(yq e .concourse.namespace $PARAMS_YAML)
OKTA_AUTH_SERVER_CN=$(yq e .okta.auth-server-fqdn $PARAMS_YAML)
export OKTA_AUTH_SERVER_CA_CERT="$(cat keys/letsencrypt-ca.pem)"
export OKTA_CONCOURSE_APP_CLIENT_ID=$(yq e .okta.concourse-app-client-id $PARAMS_YAML)
export OKTA_CONCOURSE_APP_CLIENT_SECRET=$(yq e .okta.concourse-app-client-secret $PARAMS_YAML)
export OIDC_ISSUER=https://$OKTA_AUTH_SERVER_CN/oauth2/default
ADMIN_PASSWORD=$(yq e .concourse.admin-password $PARAMS_YAML)
export ADMIN_CREDS="admin:$ADMIN_PASSWORD"

mkdir -p generated/$CLUSTER_NAME/concourse/

cp concourse/concourse-values-contour-template.yaml generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml

# yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.oidcCaCert" -- "${OKTA_AUTH_SERVER_CA_CERT}"
yq e -i --unwrapScalar=false ".secrets.oidcCaCert = strenv(OKTA_AUTH_SERVER_CA_CERT)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
yq e -i ".secrets.localUsers = env(ADMIN_CREDS)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".web.ingress.hosts[0] = env(CONCOURSE_FQDN)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".web.ingress.tls[0].hosts[0] = env(CONCOURSE_FQDN)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".concourse.web.externalUrl = env(CONCOURSE_URL)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".concourse.web.auth.oidc.issuer = env(OIDC_ISSUER)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".secrets.oidcClientId = env(OKTA_CONCOURSE_APP_CLIENT_ID)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 
yq e -i ".secrets.oidcClientSecret = env(OKTA_CONCOURSE_APP_CLIENT_SECRET)" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml 

# generate the helm manifest and make sure the web pod trusts let's encrypt
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update

# NOTE: Through testing setting the OIDC CA in values.yaml did not work as expected, so we are mounting the let's encrypt CA onto the worker pods via ytt overlay
helm template concourse concourse/concourse -f generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml --namespace $CONCOURSE_NAMESPACE --version=14.5.6 | 
  ytt -f - -f overlay/trust-certificate --ignore-unknown-comments \
    --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/concourse/helm-manifest.yaml

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kapp deploy -a concourse  \
  -f generated/$CLUSTER_NAME/concourse/helm-manifest.yaml \
  -n $CONCOURSE_NAMESPACE \
  -y
 