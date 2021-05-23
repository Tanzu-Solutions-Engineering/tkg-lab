#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

export CLUSTER_NAME=$(yq e .workload-cluster.name $PARAMS_YAML)
export ARGOCD_CN=$(yq e .argocd.server-fqdn $PARAMS_YAML)
export ARGOCD_PASSWORD=$(yq e .argocd.password $PARAMS_YAML)

# Login with the cli
argocd login $ARGOCD_CN --username admin --password $ARGOCD_PASSWORD

# Collect the necessary configuration
mkdir -p generated/$CLUSTER_NAME/argocd/
cp argocd/01-namespace.yaml generated/$CLUSTER_NAME/argocd/
cp argocd/02-serviceaccount.yaml generated/$CLUSTER_NAME/argocd/
cp argocd/03-clusterrolebinding.yaml generated/$CLUSTER_NAME/argocd/

# Apply the configuration
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
kubectl apply -f generated/$CLUSTER_NAME/argocd/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/argocd/02-serviceaccount.yaml
kubectl apply -f generated/$CLUSTER_NAME/argocd/03-clusterrolebinding.yaml

# Create kubeconfig context with Service Account secret
export TOKEN_SECRET=$(kubectl get serviceaccount -n argocd argocd -o jsonpath='{.secrets[0].name}')
export TOKEN=$(kubectl get secret -n argocd $TOKEN_SECRET -o jsonpath='{.data.token}' | base64 --decode)
kubectl config set-credentials $CLUSTER_NAME-argocd-token-user --token $TOKEN
kubectl config set-context $CLUSTER_NAME-argocd-token-user@$CLUSTER_NAME \
  --user $CLUSTER_NAME-argocd-token-user \
  --cluster $CLUSTER_NAME

# Add the config setup with the service account you created
argocd cluster add $CLUSTER_NAME-argocd-token-user@$CLUSTER_NAME

# See the clusters added
argocd cluster list
