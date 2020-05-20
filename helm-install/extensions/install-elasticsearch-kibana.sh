
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
helm upgrade --install elasticsearch-kibana ./tkg-extensions-helm-charts/elasticsearch-kibana-0.1.0.tgz \
--set elasticsearch.host=$(yq r $PARAM_FILE elasticsearch.host) \
--set kibana.host=$(yq r $PARAM_FILE kibana.host)