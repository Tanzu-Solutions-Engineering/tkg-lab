
echo 'Install Velero on AWS TKG Cluster'


#kubectl delete clusterrolebinding cert-manager-leaderelection

export AWS_BUCKET=$(yq r ./params.yml svcCluster.velero-bucket)
export AWS_REGION=$(yq r ./params.yml aws.region)
export CLUSTER_NAME=$(yq r ./params.yml svcCluster.name)

echo 'Velero Backup Bucket' $AWS_VELERO_BUCKET
echo $AWS_REGION

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.1 \
    --bucket $AWS_BUCKET \
    --backup-location-config region=$AWS_REGION \
    --snapshot-location-config region=$AWS_REGION \
    --secret-file credentials-velero
velero schedule create daily-$1-cluster-backup --schedule "0 7 * * *"
velero backup get
velero schedule get


mv velero-policy.json ./k8/scripts/velero
mv aws-valero-access-key.json ./k8/scripts/velero
mv credentials-velero ./k8/scripts/velero
