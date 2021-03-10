#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export DEX_CN=$(yq e .management-cluster.dex-fqdn $PARAMS_YAML)
export PINNIPED_CN=$(yq e .management-cluster.pinniped-fqdn $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/pinniped/

# TODO: This is a temporary fix until this is updated with the add-on.  Addresses noise logs in pinniped-concierge
kubectl apply -f tkg-extensions-mods-examples/authentication/pinniped/pinniped-rbac-extension.yaml

cp tkg-extensions-mods-examples/authentication/pinniped/dex-ingress.yaml  generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-ingress.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/dex-certificate.yaml  generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-certificate.yaml  generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

yq e -i '.spec.dnsNames[0] = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-certificate.yaml
yq e -i '.spec.dnsNames[0] = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml
yq e -i '.spec.virtualhost.fqdn = env(DEX_CN)' generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
yq e -i '.spec.virtualhost.fqdn = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

kubectl apply -f generated/$CLUSTER_NAME/pinniped/dex-ingress.yaml
kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

while dig $DEX_CN | grep "ANSWER SECTION" ; [ $? -ne 0 ]; do
	echo Waiting for external-dns to complete configuration of DNS to satisfy $DEX_CN
	sleep 5s
done

while nslookup $PINNIPED_CN | grep "ANSWER SECTION" ; [ $? -ne 0 ]; do
	echo Waiting for external-dns to complete  configuration of DNS to satisfy for $PINNIPED_CN
	sleep 5s
done

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


kubectl get secret $CLUSTER_NAME-pinniped-addon -n tkg-system -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

export PINNIPED_SVC_ENDPOINT=https://$PINNIPED_CN
export DEX_SVC_ENDPOINT=https://$DEX_CN
export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`

yq e -i '.custom_tls_secret = "custom-auth-cert-tls"' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# TODO: REMOVE THESE COMMENTED LINES
# yq e -i '.pinniped.supervisor_svc_external_dns = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_svc_endpoint = env(PINNIPED_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.supervisor_ca_bundle_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_issuer_url = env(DEX_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
# yq e -i '.pinniped.upstream_oidc_tls_ca_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

add_yaml_doc_seperator generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# This will trigger the add-on manager to run a pinniped-post-deploy job.  We need the number of the most recent version
POST_DEPLOY_JOB_NUMBER_COMPLETED=$(kubectl get jobs -n pinniped-supervisor | tail -n 1 | awk '{print $1}' | awk -F"-" '{print $6}')

kubectl create secret generic $CLUSTER_NAME-pinniped-addon --from-file=values.yaml=generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml -n tkg-system -o yaml --type=tkg.tanzu.vmware.com/addon --dry-run=client | kubectl apply -f-
kubectl annotate secret $CLUSTER_NAME-pinniped-addon --overwrite -n tkg-system tkg.tanzu.vmware.com/addon-type=authentication/pinniped
kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n tkg-system tkg.tanzu.vmware.com/addon-name=pinniped
kubectl label secret $CLUSTER_NAME-pinniped-addon --overwrite=true -n tkg-system tkg.tanzu.vmware.com/cluster-name=$CLUSTER_NAME

# Now we must wait for post deploy job to run.  We will first 
NEXT_POST_DEPLOY_JOB_NUMBER=`expr $POST_DEPLOY_JOB_NUMBER_COMPLETED + 1`

while kubectl get jobs -n pinniped-supervisor | grep pinniped-post-deploy-job-ver-$NEXT_POST_DEPLOY_JOB_NUMBER | grep "1/1"; [ $? -ne 0 ]; do
	echo "Waiting for pinniped-post-deploy-job-ver-$NEXT_POST_DEPLOY_JOB_NUMBER job to be completed"
	sleep 5s
done


# Now must patch dex config map to tell it about the proper FQDNs
kubectl get cm dex -n tanzu-system-auth -ojsonpath="{.data.config\.yaml}" > generated/$CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.issuer = env(DEX_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.staticClients[0].redirectURIs[0] = env(PINNIPED_SVC_ENDPOINT)+"/callback"' generated/$CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.connectors[0].config.redirectURI = env(DEX_SVC_ENDPOINT)+"/callback"' generated/$CLUSTER_NAME/pinniped/dex-cm-config.yaml
kubectl create cm dex -n tanzu-system-auth --from-file=config.yaml=generated/$CLUSTER_NAME/pinniped/dex-cm-config.yaml -o yaml --dry-run=client | kubectl apply -f-
# And bounce dex
kubectl set env deployment dex --env="LAST_RESTART=$(date)" --namespace tanzu-system-auth

# Validate: k get cm dex -n tanzu-system-auth -oyaml

# Now patch the CRDs - This is a hack because there is no way to configure this information

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
# Get CA: k get oidcidentityprovider -n pinniped-supervisor -ojsonpath="{.items[0].spec.tls.certificateAuthorityData}" | base64 --decode

kubectl patch jwtauthenticator tkg-jwt-authenticator \
	-n pinniped-concierge \
	--type json \
	-p="[{'op': 'replace', 'path': '/spec/issuer', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/audience', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/spec/tls/certificateAuthorityData', 'value':$CA_BUNDLE}]"
# Validate: k get jwtauthenticator -n pinniped-concierge -oyaml
# Get CA k get jwtauthenticator -n pinniped-concierge -ojsonpath="{.items[0].spec.tls.certificateAuthorityData}" | base64 --decode

# Validate: k get jwtauthenticator,federationdomain,oidcidentityprovider -A

kubectl patch cm pinniped-info \
	-n kube-public \
	--type json \
	-p="[{'op': 'replace', 'path': '/data/issuer', 'value':$PINNIPED_SVC_ENDPOINT},{'op': 'replace', 'path': '/data/issuer_ca_bundle_data', 'value':$CA_BUNDLE}]"
# Validate: k get cm pinniped-info -n kube-public -oyaml
# Get CA: k get cm pinniped-info -n kube-public -ojsonpath="{.data.issuer_ca_bundle_data}" | base64 --decode
