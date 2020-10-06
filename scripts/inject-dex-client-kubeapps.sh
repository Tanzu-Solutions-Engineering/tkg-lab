# bin/bash -e

if [ ! $# -eq 3 ]; then
  echo "Must supply Mgmt and cluster and Gangway CN as args"
  exit 1
fi
MGMT_CLUSTER_NAME=$1
CLUSTER_NAME=$2
GANGWAY_CN=$3

## Adds additional path to the Shared Services DEX Entry for kubeapps OIDC
KUBEAPPS="      - 'https://$(yq r $PARAMS_YAML kubeapps.server-fqdn)/oauth2/callback'"

# Ensure that the cluster already has an entry in the Dex configuration, else exit
cat generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml | grep "id: $CLUSTER_NAME"
exists=$?
if [ $exists -eq 0 ]; then

    # Find the Gangway CN entry in the redirect list for the cluster and add the Kubeapps redirect URL below that
    awk "1;/$GANGWAY_CN/{print \"$KUBEAPPS\"}" generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml > tmp && mv tmp generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml

    kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME

    kubectl apply -f generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml
    #force recycle of dex pod(s)
    kubectl set env deployment dex --env="LAST_RESTART=$(date)" --namespace tanzu-system-auth

    #switch back
    kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
else
    echo "An entry for $CLUSTER_NAME needs to be present in the dex config for this to work."
    exit 1;
fi

