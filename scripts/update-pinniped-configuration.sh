#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export PINNIPED_CN=$(yq e .management-cluster.pinniped-fqdn $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/pinniped/

cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-ingress.yaml generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml
cp tkg-extensions-mods-examples/authentication/pinniped/pinniped-certificate.yaml generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

yq e -i '.spec.dnsNames[0] = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml
yq e -i '.spec.virtualhost.fqdn = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-ingress.yaml

while dig $PINNIPED_CN | grep "ANSWER SECTION" ; [ $? -ne 0 ]; do
	echo Waiting for external-dns to complete  configuration of DNS to satisfy for $PINNIPED_CN
	sleep 5
done

kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-certificate.yaml

while kubectl get certificate custom-pinniped-cert -n pinniped-supervisor | grep True ; [ $? -ne 0 ]; do
	echo Pinniped certificate is not yet ready
	sleep 5
done

kubectl get secret $CLUSTER_NAME-pinniped-addon -n tkg-system -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

export PINNIPED_SVC_ENDPOINT=https://$PINNIPED_CN
if [ `uname -s` = 'Darwin' ];
then
	export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`
else
	export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64 -w 0`
fi

yq e -i '.custom_tls_secret = "custom-auth-cert-tls"' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
yq e -i '.pinniped.supervisor_svc_external_dns = env(PINNIPED_CN)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
yq e -i '.pinniped.supervisor_ca_bundle_data = env(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml
yq e -i '.pinniped.supervisor_svc_endpoint = env(PINNIPED_SVC_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml

# Deleting the existing job.  It will be recreated when the pinniped-addon secret is updated below.  And then gives us a chance to wait until job is competed
kubectl delete job pinniped-post-deploy-job -n pinniped-supervisor

if [ `uname -s` = 'Darwin' ];
then
	NEW_VALUES=`cat generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml | base64`

else
	NEW_VALUES=`cat generated/$CLUSTER_NAME/pinniped/pinniped-addon-values.yaml | base64 -w 0`
fi

kubectl patch secret $CLUSTER_NAME-pinniped-addon -n tkg-system -p '{"data": {"values.yaml": "'$NEW_VALUES'"}}'

# Wait until job is completed.
while kubectl get jobs -n pinniped-supervisor | grep "1/1"; [ $? -ne 0 ]; do
	echo "Waiting for pinniped-post-deploy-job job to be completed"
	sleep 5
done

# Now patch the CRDs - This is a hack because there is no way to configure this information

kubectl patch federationdomain pinniped-federation-domain \
	-n pinniped-supervisor \
	--type json \
	-p="[{'op': 'replace', 'path': '/spec/issuer', 'value':$PINNIPED_SVC_ENDPOINT}]"

# Validate: k get federationdomain -n pinniped-supervisor -oyaml

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
