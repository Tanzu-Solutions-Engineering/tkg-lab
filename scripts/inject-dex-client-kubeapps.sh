#! /bin/bash -e

MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

## Adds additional path to the Shared Services DEX Entry for kubeapps OIDC
export KUBEAPPS_URL="https://$(yq e .kubeapps.server-fqdn $PARAMS_YAML)/oauth2/callback"

yq e -i '.staticClients[1].redirectURIs[0] = env(KUBEAPPS_URL)' generated/$MGMT_CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.staticClients[1].id = "kubeapps"' generated/$MGMT_CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.staticClients[1].name = "kubeapps"' generated/$MGMT_CLUSTER_NAME/pinniped/dex-cm-config.yaml
yq e -i '.staticClients[1].secret = "FOO_SECRET"' generated/$MGMT_CLUSTER_NAME/pinniped/dex-cm-config.yaml

kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME

kubectl create cm dex -n tanzu-system-auth --from-file=config.yaml=generated/$MGMT_CLUSTER_NAME/pinniped/dex-cm-config.yaml -o yaml --dry-run=client | kubectl apply -f-
# And bounce dex
kubectl set env deployment dex --env="LAST_RESTART=$(date)" --namespace tanzu-system-auth

