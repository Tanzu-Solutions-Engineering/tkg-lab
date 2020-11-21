# bin/bash -e

if [ ! $# -eq 3 ]; then
  echo "Must supply Mgmt and workload cluster name and Gangway CN as args"
  exit 1
fi
MGMT_CLUSTER_NAME=$1
WORKLOAD_CLUSTER_NAME=$2
GANGWAY_CN=$3

#Only inject if it isn't already there
cat generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml | grep "id: $WORKLOAD_CLUSTER_NAME"
exists=$?
if [ $exists -eq 1 ]; then

    cp tkg-extensions-mods-examples/authentication/dex/aws/oidc/static-client.yaml generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml
    yq write -d0 generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml -i "dex.config.staticClients[0].id" $WORKLOAD_CLUSTER_NAME
    yq write -d0 generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml -i "dex.config.staticClients[0].redirectURIs[0]" "https://$GANGWAY_CN/callback"
    yq write -d0 generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml -i "dex.config.staticClients[0].name" $WORKLOAD_CLUSTER_NAME
    yq write -d0 generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml -i "dex.config.staticClients[0].secret" "FOO_SECRET"

    # Please note that yq version 3.4 has a breaking change requiring you to explicity specify =append in the merge strategy. https://github.com/mikefarah/yq/releases/tag/3.4.0
    # the following line will fail with yq version 3.3
    yq merge -a=append -i generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml generated/$MGMT_CLUSTER_NAME/dex/$WORKLOAD_CLUSTER_NAME-static-client.yaml -P

    # Add in the document seperator that yq removes
    if [ `uname -s` = 'Darwin' ];
    then
      sed -i '' '3i\
      ---\
      ' generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml
    else
      sed -i -e '3i\
      ---\
      ' generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml
    fi

    kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME

    # Update the dex data values secret
    kubectl create secret generic dex-data-values --from-file=values.yaml=generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml -n tanzu-system-auth -o yaml --dry-run=client | kubectl replace -f-

    # Force reconciliation of the dex app
    kubectl patch app dex \
      -n tanzu-system-auth \
      --type json \
      -p='[{"op": "replace", "path": "/spec/paused", "value":true}]'
    kubectl patch app dex \
      -n tanzu-system-auth \
      --type json \
      -p='[{"op": "replace", "path": "/spec/paused", "value":false}]'

    while [[ $(kubectl get app dex -n tanzu-system-auth -o yaml | yq r - status.friendlyDescription ) != "Reconcile succeeded" ]] ; do
      echo Dex extension is not yet ready
      sleep 5s
    done

    #switch back
    kubectl config use-context $WORKLOAD_CLUSTER_NAME-admin@$WORKLOAD_CLUSTER_NAME
fi
