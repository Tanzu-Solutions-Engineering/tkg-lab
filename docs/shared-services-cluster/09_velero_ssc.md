# Install Velero and Setup Nightly Backup

This lab is currently only available when deploying on AWS

brew install velero

Follow [Velero Plugins for AWS Guide](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup).  I chose **Option 1** for **Set Permissions for Velero Step**.

Store your credentials-velero file in keys/

Go to AWS console S3 service and create a bucket for cluster backups.

## Set configuration parameters

The scripts to prepare the YAML to deploy velero depend on a parameters to be set.  Ensure the following are set in `params.yaml` based upon your environment:

```yaml
velero.bucket: my-bucket
veloreo.region: us-east-2
```

## Prepare Manifests and Deploy Velero

Prepare the YAML manifests for the related velero K8S objects and then run the following script to install velero and configure a nightly backup.

```bash
./scripts/velero.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

## Validation Step

Ensure schedule is created and the first backup is starting

```bash
velero schedule get
velero backup get | grep $(yq r $PARAMS_YAML shared-services-cluster.name)
```

## Go to Next Step

[Install FluentBit on Shared Services Cluster](../mgmt-cluster/09_fluentbit_mgmt.md)
