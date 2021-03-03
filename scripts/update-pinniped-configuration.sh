#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export DEX_CN=$(yq e .management-cluster.dex-fqdn $PARAMS_YAML)
export PINNIPED_CN=$(yq e .management-cluster.pinniped-fqdn $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/pinniped/

cp tkg-extensions-mods-examples/authentication/pinniped/dex-ingress.yaml  generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-ingress.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/dex-certificate.yaml  generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-certificate.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

yq e -i '.spec.dnsNames[0] = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
yq e -i '.spec.dnsNames[0] = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml
yq e -i '.spec.virtualhost.fqdn = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
yq e -i '.spec.virtualhost.fqdn = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

kubectl apply -f generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml



while kubectl get certificate custom-dex-cert -n tanzu-system-auth | grep True ; [ $? -ne 0 ]; do
	echo Dex certificate is not yet ready
	sleep 5s
done

while kubectl get certificate custom-pinniped-cert -n pinniped-supervisor | grep True ; [ $? -ne 0 ]; do
	echo Pinniped certificate is not yet ready
	sleep 5s
done

kubectl apply -f generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

kubectl get secret $CLUSTER_NAME-pinniped-addon -n tkg-system -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

export PINNIPED_SVC_ENDPOINT=https://$PINNIPED_CN
export DEX_SVC_ENDPOINT=https://$DEX_CN
export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`
# TODO: REMOVE THESE COMMENTED LINES
# export OIDC_IDENTITY_PROVIDER_ISSUER_URL=https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)

yq e -i '.custom_tls_secret = "custom-auth-cert-tls"' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_svc_external_dns = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_svc_endpoint = env(PINNIPED_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_ca_bundle_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_issuer_url = env(DEX_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_tls_ca_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.dex.config.oidc.issuer = env(OIDC_IDENTITY_PROVIDER_ISSUER_URL)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

add_yaml_doc_seperator generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# kubectl create secret generic $CLUSTER_NAME-pinniped-addon --from-file=values.yaml=generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml -n tkg-system -o yaml --type=tkg.tanzu.vmware.com/addon --dry-run=client | kubectl apply -f-



