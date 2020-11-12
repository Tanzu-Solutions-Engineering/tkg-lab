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

    kubectl create secret generic dex-data-values --from-file=values.yaml=generated/$MGMT_CLUSTER_NAME/dex/dex-data-values.yaml -n tanzu-system-auth -o yaml --dry-run=client | kubectl replace -f-

    # Add paused = false to stop reconciliation
    sed -i '' -e 's/paused: true/paused: false/g' generated/$MGMT_CLUSTER_NAME/dex/dex-extension.yaml
    kubectl apply -f generated/$MGMT_CLUSTER_NAME/dex/dex-extension.yaml

    # Wait until dex app is reconciliend
    while kubectl get app dex -n tanzu-system-auth | grep dex | grep "Reconcile succeeded" ; [ $? -ne 0 ]; do
      echo Dex extension is not yet reconcilied
      sleep 5s
    done

    # Add paused = true to stop reconciliation
    sed -i '' -e 's/paused: false/paused: true/g' generated/$MGMT_CLUSTER_NAME/dex/dex-extension.yaml
    kubectl apply -f generated/$MGMT_CLUSTER_NAME/dex/dex-extension.yaml

    # Wait until dex app is paused
    while kubectl get app dex -n tanzu-system-auth | grep dex | grep "paused" ; [ $? -ne 0 ]; do
      echo Dex extension is not yet paused
      sleep 5s
    done

    kubectl patch deployment dex \
      -n tanzu-system-auth \
      --type json \
      -p='[{"op": "replace", "path": "/spec/template/spec/volumes/1/secret/secretName", "value":"dex-cert-tls-valid"}]'

    #switch back
    kubectl config use-context $WORKLOAD_CLUSTER_NAME-admin@$WORKLOAD_CLUSTER_NAME
fi
