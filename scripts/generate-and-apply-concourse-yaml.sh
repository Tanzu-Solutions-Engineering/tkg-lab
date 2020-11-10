#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
CONCOURSE_URL=$(yq r $PARAMS_YAML concourse.fqdn)
CONCOURSE_NAMESPACE=$(yq r $PARAMS_YAML concourse.namespace)
OKTA_AUTH_SERVER_CN=$(yq r $PARAMS_YAML okta.auth-server-fqdn)
OKTA_AUTH_SERVER_CA_CERT="$(cat keys/letsencrypt-ca.pem)"
OKTA_CONCOURSE_APP_CLIENT_ID=$(yq r $PARAMS_YAML okta.concourse-app-client-id)
OKTA_CONCOURSE_APP_CLIENT_SECRET=$(yq r $PARAMS_YAML okta.concourse-app-client-secret)

mkdir -p generated/$CLUSTER_NAME/concourse/

cp concourse/concourse-values-contour-template.yaml generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i '' -e "s/OKTA_AUTH_SERVER_CN/$OKTA_AUTH_SERVER_CN/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i '' -e "s/OKTA_CONCOURSE_APP_CLIENT_ID/$OKTA_CONCOURSE_APP_CLIENT_ID/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i '' -e "s/OKTA_CONCOURSE_APP_CLIENT_SECRET/$OKTA_CONCOURSE_APP_CLIENT_SECRET/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
else
  sed -i -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i -e "s/$OKTA_AUTH_SERVER_CN/$OKTA_AUTH_SERVER_CN/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i -e "s/OKTA_CONCOURSE_APP_CLIENT_ID/$OKTA_CONCOURSE_APP_CLIENT_ID/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
  sed -i -e "s/OKTA_CONCOURSE_APP_CLIENT_SECRET/$OKTA_CONCOURSE_APP_CLIENT_SECRET/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
fi

yq write -d0 generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml -i "secrets.oidcCaCert" -- "${OKTA_AUTH_SERVER_CA_CERT}"

# generate the helm manifest and make sure the web pod trusts let's encrypt
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update

helm template concourse concourse/concourse -f generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml --namespace $CONCOURSE_NAMESPACE | 
  ytt -f - -f overlay/trust-certificate --ignore-unknown-comments \
    --data-value certificate="$(cat keys/letsencrypt-ca.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/concourse/helm-manifest.yaml

kapp deploy -a concourse  \
  -n tanzu-kapp \
  --into-ns $CONCOURSE_NAMESPACE \
  -f generated/$CLUSTER_NAME/concourse/helm-manifest.yaml \
 
