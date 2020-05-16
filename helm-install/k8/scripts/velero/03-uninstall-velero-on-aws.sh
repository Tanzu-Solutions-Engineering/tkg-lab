
echo 'Uninstall Velero on AWS TKG Cluster'

kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
