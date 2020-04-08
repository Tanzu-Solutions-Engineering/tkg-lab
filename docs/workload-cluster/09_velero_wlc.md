# Install Velero and Setup Nightly Backup

Go to AWS console S3 service and create a bucket for wlc-1 backups.

Now install velero on the wlc-1 cluster and schedule nightly backup

```bash
# Update with your bucket name and region
export VELERO_BUCKET=YOUR_BUCKET_NAME
export REGION=YOUR_REGION
export CLUSTER_NAME=wlc-1
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.1 \
    --bucket $VELERO_BUCKET \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION \
    --secret-file keys/credentials-velero
velero schedule create daily-$CLUSTER_NAME-cluster-backup --schedule "0 7 * * *"
velero backup get
velero schedule get
```