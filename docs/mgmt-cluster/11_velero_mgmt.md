# Install Velero and Setup Nightly Backup

This lab is currently only available when deploying on AWS

brew install velero

Follow [Velero Plugins for AWS Guide](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup).  I chose **Option 1** for **Set Permissions for Veloro Step**.

Store your credentials-velero file in keys/

Go to AWS console S3 service and create a bucket for backups.

One more step is required or else the cluster backups will fail.  Cert-manager has a broken reference where the clusterrolebinding cert-manager-leaderelection references a clusterrole cert-manager-leaderelection that does not exist.  This causes the backup to partially fail.  So we will go ahead and delete this invalid clusterrolebinding.

Now install velero on the management cluster and schedule nightly backup

```bash
kubectl delete clusterrolebinding cert-manager-leaderelection
export VELERO_BUCKET=pa-dpfeffer-mgmt-velero
export REGION=us-east-2
export CLUSTER_NAME=mgmt
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
