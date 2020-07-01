
#!/bin/bash -e
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
helm upgrade -n cert-manager --create-namespace --install cert-manager ./tkg-extensions-helm-charts/cert-manager-0.1.0.tgz --wait