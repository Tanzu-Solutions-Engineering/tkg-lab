#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
CONCOURSE_URL=$(yq r $PARAMS_YAML concourse.fqdn)
CONCOURSE_NAMESPACE=$(yq r $PARAMS_YAML concourse.namespace)
OKTA_AUTH_SERVER_CN=$(yq r $PARAMS_YAML okta.auth-server-fqdn)
OKTA_AUTH_SERVER_CA_CERT="$(cat keys/letsencrypt-ca.pem)"
OKTA_CONCOURSE_APP_CLIENT_ID=$(yq r $PARAMS_YAML okta.concourse-app-client-id)
OKTA_CONCOURSE_APP_CLIENT_SECRET=$(yq r $PARAMS_YAML okta.concourse-app-client-secret)
ADMIN_PASSWORD=$(yq r $PARAMS_YAML concourse.admin-password)

mkdir -p generated/$CLUSTER_NAME/concourse/

cp concourse/concourse-values-contour-template.yaml generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml

yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.oidcCaCert" -- "${OKTA_AUTH_SERVER_CA_CERT}"
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.localUsers" "admin:$ADMIN_PASSWORD"
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "web.ingress.hosts[0]" $CONCOURSE_URL
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "web.ingress.tls[0].hosts[0]" $CONCOURSE_URL
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "concourse.web.externalUrl" https://$CONCOURSE_URL
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "concourse.web.auth.oidc.issuer" https://$OKTA_AUTH_SERVER_CN/oauth2/default
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.oidcClientId" $OKTA_CONCOURSE_APP_CLIENT_ID
yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.oidcClientSecret" $OKTA_CONCOURSE_APP_CLIENT_SECRET

# generate the helm manifest and make sure the web pod trusts let's encrypt
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update

# NOTE: Through testing setting the OIDC CA in values.yaml did not work as expected, so we are mounting the let's encrypt CA onto the worker pods via ytt overlay
helm template concourse concourse/concourse -f generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml --namespace $CONCOURSE_NAMESPACE | 
  ytt -f - -f overlay/trust-certificate --ignore-unknown-comments \
    --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/concourse/helm-manifest.yaml

kapp deploy -a concourse  \
  -f generated/$CLUSTER_NAME/concourse/helm-manifest.yaml \
  -n $CONCOURSE_NAMESPACE \
  -y
 