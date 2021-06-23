#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

export CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
export ARGOCD_CN=$(yq e .argocd.server-fqdn $PARAMS_YAML)
export ARGOCD_PASSWORD=$(yq e .argocd.password $PARAMS_YAML)
export ARGOCD_HTPASSWORD=$(htpasswd -nbBC 10 "" $ARGOCD_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')

mkdir -p generated/$CLUSTER_NAME/argocd/
cp argocd/01-namespace.yaml generated/$CLUSTER_NAME/argocd/
cp argocd/values.yaml generated/$CLUSTER_NAME/argocd/
cp argocd/httpproxy.yaml generated/$CLUSTER_NAME/argocd/

yq e -i '.spec.virtualhost.fqdn = env(ARGOCD_CN)' generated/$CLUSTER_NAME/argocd/httpproxy.yaml
yq e -i '.server.certificate.domain = env(ARGOCD_CN)' generated/$CLUSTER_NAME/argocd/values.yaml
yq e -i '.configs.secret.argocdServerAdminPassword = env(ARGOCD_HTPASSWORD)' generated/$CLUSTER_NAME/argocd/values.yaml

echo "Beginning ArgoCD install..."

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl apply -f generated/$CLUSTER_NAME/argocd/01-namespace.yaml

helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd \
  -f generated/$CLUSTER_NAME/argocd/values.yaml \
  --namespace argocd \
  --version "3.5.0"
kubectl apply -f generated/$CLUSTER_NAME/argocd/httpproxy.yaml
