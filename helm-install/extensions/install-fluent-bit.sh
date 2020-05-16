
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

helm install fluent-bit ./tkg-extensions-helm-charts/fluent-bit-0.1.0.tgz \
 --set elasticsearch.host=$(yq r $PARAM_FILE elasticsearch.host) \
 --set elasticsearch.port=$(yq r $PARAM_FILE elasticsearch.port) \
 --set tkg.clusterName=$CLUSTER_NAME \
 --set tkg.instanceName=$CLUSTER_NAME \
 --set namespace.enabled=false
