# bin/bash -e

if [ ! $# -eq 3 ]; then
  echo "Must supply Mgmt and workload cluster name and Gangway CN as args"
  exit 1
fi
MGMT_CLUSTER_NAME=$1
WORKLOAD_CLUSTER_NAME=$2
GANGWAY_CN=$3

#Only inject if it isn't already there
cat generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml | grep "id: $WORKLOAD_CLUSTER_NAME"
exists=$?
if [ $exists -eq 1 ]; then
    LINENUM=`sed -n '/staticClients/=' generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml`
    VAR1="    - id: $WORKLOAD_CLUSTER_NAME"
    VAR1=$VAR1"\n      redirectURIs:"
    VAR1=$VAR1"\n      - 'https://$GANGWAY_CN/callback'"
    VAR1=$VAR1"\n      name: '$WORKLOAD_CLUSTER_NAME'"
    VAR1=$VAR1"\n      secret: FOO_SECRET"
    echo "Adding Dex Client:"
    echo $VAR1

    awk -v line="$LINENUM" -v lines="$VAR1" '{print} NR==line{print lines}' generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml > tmp && mv tmp generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml

    kubectl config use-context $MGMT_CLUSTER_NAME-admin@$MGMT_CLUSTER_NAME
    kubectl apply -f generated/$MGMT_CLUSTER_NAME/dex/04-cm.yaml
    #force recycle of dex pod(s)
    kubectl get po -n tanzu-system-auth
    kubectl set env deployment dex --env="LAST_RESTART=$(date)" --namespace tanzu-system-auth
    kubectl get po -n tanzu-system-auth
    #switch back
    kubectl config use-context $WORKLOAD_CLUSTER_NAME-admin@$WORKLOAD_CLUSTER_NAME
fi

