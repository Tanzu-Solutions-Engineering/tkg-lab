#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and grafana fqdn as args"
  exit 1
fi
CLUSTER_NAME=$1
export GRAFANA_FQDN=$2
GRAFANA_PASSWORD=$(yq e .grafana.admin-password $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/monitoring/

kubectl create ns tanzu-system-dashboards --dry-run=client -oyaml | kubectl apply -f -

# Create certificate
cp tkg-extensions-mods-examples/monitoring/grafana-cert.yaml generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
yq e -i ".spec.dnsNames[0] = env(GRAFANA_FQDN)" generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
kubectl apply -f generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-dashboards grafana-cert | grep True ; [ $? -ne 0 ]; do
	echo Grafana certificate is not yet ready
	sleep 5
done

# TODO: Created https://github.com/vmware-tanzu/community-edition/issues/2947 requsting that a paramater be added to allow you to specify secret name
#    instead of providing the cert in data values.yaml.  Once that has been delivered and flows downstream, we can update this section of the code

# Read Grafana certificate details and store in files
export GRAFANA_CERT_CRT=$(kubectl get secret grafana-cert-tls -n tanzu-system-dashboards -o=jsonpath={.data."tls\.crt"} | base64 --decode)
export GRAFANA_CERT_KEY=$(kubectl get secret grafana-cert-tls -n tanzu-system-dashboards -o=jsonpath={.data."tls\.key"} | base64 --decode)

if [ `uname -s` = 'Darwin' ];
then
  export ADMIN_PASSWORD=$(echo -n $GRAFANA_PASSWORD | base64)
else
  export ADMIN_PASSWORD=$(echo -n $GRAFANA_PASSWORD | base64 -w 0)
fi

yq e ".grafana.secret.admin_password = env(ADMIN_PASSWORD)" --null-input > generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i '.grafana.service.type = "ClusterIP"' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i ".ingress.virtual_host_fqdn = env(GRAFANA_FQDN)" generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml -i
yq e -i '.ingress.tlsCertificate."tls.crt" = strenv(GRAFANA_CERT_CRT)' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i '.ingress.tlsCertificate."tls.key" = strenv(GRAFANA_CERT_KEY)' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i '.namespace = "tanzu-system-dashboards"' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml

# Apply Monitoring
# Retrieve the most recent version number.  There may be more than one version available and we are assuming that the most recent is listed last,
# thus supplying -1 as the index of the array
VERSION=$(tanzu package available list -oyaml | yq eval '.[] | select(.display-name == "grafana") | .latest-version' -)
tanzu package install grafana \
    --package-name grafana.tanzu.vmware.com \
    --version $VERSION \
    --namespace tanzu-kapp \
    --values-file generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml \
    --poll-timeout 10m0s
