#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and grafana fqdn as args"
  exit 1
fi
CLUSTER_NAME=$1
export GRAFANA_FQDN=$2
GRAFANA_PASSWORD=$(yq r $PARAMS_YAML grafana.admin-password)
IAAS=$(yq r $PARAMS_YAML iaas)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME


mkdir -p generated/$CLUSTER_NAME/monitoring/

# Create certificate
cp tkg-extensions-mods-examples/monitoring/grafana-cert.yaml generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
yq e -i ".spec.dnsNames[0] = env(GRAFANA_FQDN)" generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
kubectl apply -f generated/$CLUSTER_NAME/monitoring/grafana-cert.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-monitoring grafana-cert | grep True ; [ $? -ne 0 ]; do
	echo Grafana certificate is not yet ready
	sleep 5s
done

# Read Grafana certificate details and store in files
GRAFANA_CERT_CRT=$(kubectl get secret grafana-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.crt"} | base64 --decode)
GRAFANA_CERT_KEY=$(kubectl get secret grafana-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.key"} | base64 --decode)

cp tkg-extensions/extensions/monitoring/grafana/$IAAS/grafana-data-values.yaml.example generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml

export ADMIN_PASSWORD=$(echo -n $GRAFANA_PASSWORD | base64)
yq e -i ".monitoring.grafana.secret.admin_password = env(ADMIN_PASSWORD)" generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i ".monitoring.grafana.ingress.virtual_host_fqdn = env(GRAFANA_FQDN)" generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml -i
yq e -i '.monitoring.grafana.ingress.tlsCertificate."tls.crt" = strenv(GRAFANA_CERT_CRT)' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml
yq e -i '.monitoring.grafana.ingress.tlsCertificate."tls.key" = strenv(GRAFANA_CERT_KEY)' generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml

# Add in the document seperator that yq removes
add_yaml_doc_seperator generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml

# Apply Monitoring

kubectl apply -f tkg-extensions/extensions/monitoring/grafana/namespace-role.yaml
# Using the following "apply" syntax to allow for script to be rerun
kubectl create secret generic grafana-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/monitoring/grafana-data-values.yaml -n tanzu-system-monitoring -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f tkg-extensions/extensions/monitoring/grafana/grafana-extension.yaml

while kubectl get app grafana -n tanzu-system-monitoring | grep grafana | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo grafana extension is not yet ready
	sleep 5s
done   

