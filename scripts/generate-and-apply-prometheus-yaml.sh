#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 2 ]; then
  echo "Must supply cluster name and prometheus fqdn as args"
  exit 1
fi
CLUSTER_NAME=$1
PROMETHEUS_FQDN=$2

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq r $PARAMS_YAML iaas)

mkdir -p generated/$CLUSTER_NAME/monitoring/

# Create certificate
yq read tkg-extensions-mods-examples/monitoring/prometheus-cert.yaml > generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
yq write generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml -i "spec.dnsNames[0]" $PROMETHEUS_FQDN
kubectl apply -f generated/$CLUSTER_NAME/monitoring/prometheus-cert.yaml
# Wait for cert to be ready
while kubectl get certificates -n tanzu-system-monitoring prometheus-cert | grep True ; [ $? -ne 0 ]; do
	echo prometheus certificate is not yet ready
	sleep 5s
done

# Read prometheus certificate details and store in files
PROMETHEUS_CERT_CRT=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.crt"} | base64 --decode)
PROMETHEUS_CERT_KEY=$(kubectl get secret prometheus-cert-tls -n tanzu-system-monitoring -o=jsonpath={.data."tls\.key"} | base64 --decode)
echo "$PROMETHEUS_CERT_CRT" > generated/$CLUSTER_NAME/monitoring/prometheus-tls.crt
echo "$PROMETHEUS_CERT_KEY" > generated/$CLUSTER_NAME/monitoring/prometheus-tls.key

cp tkg-extensions/extensions/monitoring/prometheus/$IAAS/prometheus-data-values.yaml.example generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml

yq write -d0 generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -i "monitoring.ingress.enabled" "true"
yq write -d0 generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -i "monitoring.ingress.virtual_host_fqdn" $PROMETHEUS_FQDN
yq write -d0 generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -i "monitoring.ingress.tlsCertificate[tls.crt]" -- "$(< generated/$CLUSTER_NAME/monitoring/prometheus-tls.crt)"
yq write -d0 generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -i "monitoring.ingress.tlsCertificate[tls.key]" -- "$(< generated/$CLUSTER_NAME/monitoring/prometheus-tls.key)"

# Add in the document seperator that yq removes
if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' '3i\
  ---\
  ' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
else
  sed -i -e '3i\---\' generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml
fi

# Apply Monitoring

kubectl apply -f tkg-extensions/extensions/monitoring/prometheus/namespace-role.yaml
# Using the following "apply" syntax to allow for script to be rerun
kubectl create secret generic prometheus-data-values --from-file=values.yaml=generated/$CLUSTER_NAME/monitoring/prometheus-data-values.yaml -n tanzu-system-monitoring -o yaml --dry-run=client | kubectl apply -f-
kubectl apply -f tkg-extensions/extensions/monitoring/prometheus/prometheus-extension.yaml

while kubectl get app prometheus -n tanzu-system-monitoring | grep prometheus | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
	echo prometheus extension is not yet ready
	sleep 5s
done   

