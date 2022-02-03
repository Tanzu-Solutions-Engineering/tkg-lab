#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export MINIO_CN=$(yq e .minio.server-fqdn $PARAMS_YAML)
CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/minio/

kubectl create ns minio --dry-run=client --output yaml | kubectl apply -f -

# Add image pull secret with dockerhub creds
$TKG_LAB_SCRIPTS/add-dockerhub-pull-secret.sh minio

cat > generated/$CLUSTER_NAME/minio/minio-data-values.yaml << EOF
global:
  imagePullSecrets:
  - docker-hub-creds
auth:
  rootUser: 
  rootPassword:
service:
  type: LoadBalancer
  annotations: 	
defaultBuckets: 
persistence:
  size:
EOF

export ROOT_USER=$(yq e .minio.root-user $PARAMS_YAML)
export ROOT_PASSWORD=$(yq e .minio.root-password $PARAMS_YAML)
export PERSITENCE_SIZE=$(yq e '.minio.persistence-size // "40Gi"' $PARAMS_YAML)
export SERVICE_ANNOTATION='{"external-dns.alpha.kubernetes.io/hostname": "'$MINIO_CN'"}'
export VELERO_BUCKET=$(yq e .velero.bucket $PARAMS_YAML)

yq e -i ".auth.rootUser = env(ROOT_USER)" generated/$CLUSTER_NAME/minio/minio-data-values.yaml
yq e -i ".auth.rootPassword = env(ROOT_PASSWORD)" generated/$CLUSTER_NAME/minio/minio-data-values.yaml
yq e -i ".defaultBuckets = env(VELERO_BUCKET)" generated/$CLUSTER_NAME/minio/minio-data-values.yaml
yq e -i ".persistence.size = env(PERSITENCE_SIZE)" generated/$CLUSTER_NAME/minio/minio-data-values.yaml
# yq e -i ".service.annotations = env(SERVICE_ANNOTATION)" generated/$CLUSTER_NAME/minio/minio-data-values.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade --install minio --namespace minio bitnami/minio -f generated/$CLUSTER_NAME/minio/minio-data-values.yaml

# Wait for pod to be ready
while kubectl get po -n minio | grep Running ; [ $? -ne 0 ]; do
	echo Minio is not yet ready
	sleep 5s
done

# HACK: I was unable to use the helm chart anotation or else Avi would not provide me an external addres.  I needed to annotate after the 
# service had its address assigned.
kubectl annotate service minio "external-dns.alpha.kubernetes.io/hostname=$MINIO_CN." -n minio
