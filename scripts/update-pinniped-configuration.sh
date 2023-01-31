#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export PINNIPED_CN=$(yq e .management-cluster.pinniped-fqdn $PARAMS_YAML)
export PINNIPED_ENDPOINT=https://$PINNIPED_CN

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

if [ `uname -s` = 'Darwin' ];
then
	export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64`
else
	export CA_BUNDLE=`cat keys/letsencrypt-ca.pem | base64 -w 0`
fi

# Copy secret generated from certificate to a new one to combine both cert and CA data
kubectl get secret custom-auth-cert-tls -n pinniped-supervisor -oyaml > generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i '.metadata.name = "custom-auth-cert-tls-with-ca"' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i '.data."ca.crt" = strenv(CA_BUNDLE)' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i 'del(.metadata.annotations)' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i 'del(.metadata.creationTimestamp)' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i 'del(.metadata.uid)' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
yq e -i 'del(.metadata.resourceVersion)' generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml
kubectl apply -f generated/$CLUSTER_NAME/pinniped/pinniped-secret-with-ca.yaml

# Update add-on values
kubectl get secret $CLUSTER_NAME-pinniped-package -n tkg-system -ojsonpath="{.data.values\.yaml}" | base64 --decode > generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml
yq e -i '.custom_tls_secret = "custom-auth-cert-tls-with-ca"' generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml
yq e -i '.pinniped.supervisor_svc_external_dns = env(PINNIPED_ENDPOINT)' generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml
yq e -i '.pinniped.supervisor.service.type = "ClusterIP"' generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml


# Deleting the existing job.  It will be recreated when the pinniped-addon secret is updated below.  And then gives us a chance to wait until job is competed
kubectl delete job pinniped-post-deploy-job -n pinniped-supervisor

if [ `uname -s` = 'Darwin' ];
then
	NEW_VALUES=`cat generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml | base64`

else
	NEW_VALUES=`cat generated/$CLUSTER_NAME/pinniped/pinniped-package-values.yaml | base64 -w 0`
fi

kubectl patch secret $CLUSTER_NAME-pinniped-package -n tkg-system -p '{"data": {"values.yaml": "'$NEW_VALUES'"}}'

# Wait until job is completed.
while kubectl get jobs -n pinniped-supervisor | grep "1/1"; [ $? -ne 0 ]; do
	echo "Waiting for pinniped-post-deploy-job job to be completed"
	sleep 5
done
