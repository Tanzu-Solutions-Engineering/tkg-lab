#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export DEX_CN=$(yq e .management-cluster.dex-fqdn $PARAMS_YAML)
export PINNIPED_CN=$(yq e .management-cluster.pinniped-fqdn $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/pinniped/

# cp tkg-extensions-mods-examples/authentication/pinniped/dex-ingress.yaml  generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
# cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-ingress.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml
# cp tkg-extensions-mods-examples/authentication/pinniped/dex-certificate.yaml  generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
# cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-certificate.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

# yq e -i '.spec.dnsNames[0] = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
# yq e -i '.spec.dnsNames[0] = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml
# yq e -i '.spec.virtualhost.fqdn = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
# yq e -i '.spec.virtualhost.fqdn = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

# kubectl apply -f generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
# kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

# while kubectl get certificate custom-dex-cert -n tanzu-system-auth | grep True ; [ $? -ne 0 ]; do
# 	echo Dex certificate is not yet ready
# 	sleep 5s
# done

# while kubectl get certificate custom-pinniped-cert -n pinniped-supervisor | grep True ; [ $? -ne 0 ]; do
# 	echo Pinniped certificate is not yet ready
# 	sleep 5s
# done

# kubectl get secret -n tanzu-system-auth custom-auth-cert-tls -ojsonpath="{.data.tls\.crt}" | base64 --decode > keys/$CLUSTER_NAME-dex-tls.crt
# kubectl get secret -n tanzu-system-auth custom-auth-cert-tls -ojsonpath="{.data.tls\.key}" | base64 --decode > keys/$CLUSTER_NAME-dex-tls.key
# kubectl get secret -n pinniped-supervisor custom-auth-cert-tls -ojsonpath="{.data.tls\.key}" | base64 --decode > keys/$CLUSTER_NAME-pinniped-tls.key
# kubectl get secret -n pinniped-supervisor custom-auth-cert-tls -ojsonpath="{.data.tls\.crt}" | base64 --decode > keys/$CLUSTER_NAME-pinniped-tls.crt

# kubectl apply -f generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
# kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

# kubectl get secret $CLUSTER_NAME-pinniped-addon -n tkg-system -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

export PINNIPED_SVC_ENDPOINT=https://$PINNIPED_CN
export DEX_SVC_ENDPOINT=https://$DEX_CN
export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`

# This is a hack to use a different secret not managed by cert manager, in order to get the CA in the hte secret
# kubectl create secret generic --type=kubernetes.io/tls custom-auth-cert-tls2 -n tanzu-system-auth --from-file=tls.crt=keys/redkeep-dex-tls.crt --from-file=tls.key=keys/redkeep-dex-tls.key --dry-run=client -oyaml --from-file=ca.crt=keys/letsencrypt-ca.pem | kubectl apply -f -
# kubectl create secret generic --type=kubernetes.io/tls custom-auth-cert-tls2 -n pinniped-supervisor --from-file=tls.crt=keys/redkeep-pinniped-tls.crt --from-file=tls.key=keys/redkeep-pinniped-tls.key --dry-run=client -oyaml --from-file=ca.crt=keys/letsencrypt-ca.pem | kubectl apply -f -
# yq e -i '.custom_tls_secret = "custom-auth-cert-tls2"' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# TODO: REMOVE THESE COMMENTED LINES
# yq e -i '.pinniped.supervisor_svc_external_dns = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_svc_endpoint = env(PINNIPED_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_ca_bundle_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_issuer_url = env(DEX_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_tls_ca_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# add_yaml_doc_seperator generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# kubectl create secret generic $CLUSTER_NAME-pinniped-addon --from-file=values.yaml=generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml -n tkg-system -o yaml --type=tkg.tanzu.vmware.com/addon --dry-run=client | kubectl apply -f-
# kubectl annotate secret $CLUSTER_NAME-pinniped-addon --overwrite -n tkg-system tkg.tanzu.vmware.com/addon-type=authentication/pinniped
# kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n tkg-system tkg.tanzu.vmware.com/addon-name=pinniped
# kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n tkg-system tkg.tanzu.vmware.com/cluster-name=$CLUSTER_NAME


kubectl patch federationdomain pinniped-federation-domain \
	-n pinniped-supervisor \
	--type json \
	-p="[{'op': 'replace', 'path': '/spec/issuer', 'value':$PINNIPED_SVC_ENDPOINT}]"

# Validate: k get federationdomain -n pinniped-supervisor -oyaml

kubectl patch oidcidentityprovider dex-oidc-identity-provider \
	-n pinniped-supervisor \
	--type json \
	-p="[{'op': 'replace', 'path': '/spec/issuer', 'value':'$DEX_SVC_ENDPOINT'},{'op': 'replace', 'path': '/spec/tls/certificateAuthorityData', 'value':$CA_BUNDLE}]"
# Validate: k get oidcidentityprovider -n pinniped-supervisor -oyaml

kubectl patch jwtauthenticator tkg-jwt-authenticator \
	-n pinniped-concierge \
	--type json \
	-p="[{'op': 'replace', 'path': '/spec/issuer', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/audience', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/tls/certificateAuthorityData', 'value':$CA_BUNDLE}]"
# Validate: k get jwtauthenticator -n pinniped-concierge -oyaml

# Validate: k get jwtauthenticator,federationdomain,oidcidentityprovider -A

kubectl patch cm pinniped-info \
	-n kube-public \
	--type json \
	-p="[{'op': 'replace', 'path': '/data/issuer', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/data/issuer_ca_bundle_data', 'value':$CA_BUNDLE}]"
# Validate: k get cm pinniped-info -n kube-public -oyaml

# kubectl patch cm dex \
# 	-n tanzu-system-auth \
# 	--type json \
# 	-p="[{'op': 'replace', 'path': '/data/issuer', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/audience', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/tls/certificateAuthorityData', 'value':$CA_BUNDLE}]"

# kubectl get cm dex -n tanzu-system-auth -ojsonpath="{.data.config\.yaml}" > generated/redkeep/pinniped/dex-cm.yaml
# Validate: k get cm dex -n tanzu-system-auth -oyaml
