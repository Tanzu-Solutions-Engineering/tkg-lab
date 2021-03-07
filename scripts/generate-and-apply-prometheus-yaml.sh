#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and prometheus fqdn as args"
  exit 1
fi
CLUSTER_NAME=$1
export PROMETHEUS_FQDN=$2

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq e .iaas $PARAMS_YAML)

mkdir -p generated/$CLUSTER_NAME/monitoring/

kubectl apply -f tkg-extensions/extensions/monitoring/prometheus/namespace-role.yaml

# Create certificate
cp tkg-extensions-mods-examples/monitoring/prometheus-cert.yaml generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
yq e -i "spec.dnsNames[0] = env(PROMETHEUS_FQDN)" generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
kubectl apply -f generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-monitoring prometheus-cert | grep True ; [ $? -ne 0 ]; do
	echo prometheus certificate is not yet ready
	sleep 5s
done

# Read prometheus certificate details and store in files
export PROMETHEUS_CERT_CRT=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.crt"} | base64 --decode)
export PROMETHEUS_CERT_KEY=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.key"} | base64 --decode)

cp tkg-extensions/extensions/monitoring/prometheus/$IAAS/prometheus-data-values.yaml.example generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml

export TRUE_VALUE=true
yq e -i ".monitoring.ingress.enabled = env(TRUE_VALUE)" generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
yq e -i ".monitoring.ingress.virtual_host_fqdn = env(PROMETHEUS_FQDN)" generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
yq e -i '.monitoring.ingress.tlsCertificate."tls.crt" = strenv(PROMETHEUS_CERT_CRT)' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml 
yq e -i '.monitoring.ingress.tlsCertificate."tls.key" = strenv(PROMETHEUS_CERT_KEY)' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml 

# Add in the document seperator that yq removes
add_yaml_doc_seperator generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml

# Apply Monitoring

# Using the following "apply" syntax to allow for script to be rerun
kubectl create secret generic prometheus-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -n tanzu-system-monitoring -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f tkg-extensions/extensions/monitoring/prometheus/prometheus-extension.yaml

while kubectl get app prometheus -n tanzu-system-monitoring | grep prometheus | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo prometheus extension is not yet ready
	sleep 5s
done   

