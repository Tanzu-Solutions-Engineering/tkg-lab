# bin/bash -e

## Adds additional path to the Shared Services DEX Entry for kubeapps OIDC

MGMT_CLUSTER_NAME=$(yq r $PARAMS_YAML management-cluster.name)
SVCS_CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
GANGWAY_CN=$(yq r $PARAMS_YAML shared-services-cluster.gangway-fqdn)
KUBEAPPS="      - 'https://$(yq r $PARAMS_YAML kubeapps.server-fqdn)/oauth2/callback'"

#Only inject if it is already there
cat generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml | grep "id: $SVCS_CLUSTER_NAME"
exists=$?
if [ $exists -eq 0 ]; then
    awk "1;/$GANGWAY_CN/{print \"$KUBEAPPS\"}" generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml > tmp && mv tmp generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml

    kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME
    kubectl apply -f generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml
    #force recycle of dex pod(s)
    kubectl get po -n tanzu-system-auth
    kubectl set env deployment dex --env="LAST_RESTART=$(date)" --namespace tanzu-system-auth
    kubectl get po -n tanzu-system-auth
    #switch back
    kubectl config use-context $SVCS_CLUSTER_NAME-admin@$SVCS_CLUSTER_NAME

fi

