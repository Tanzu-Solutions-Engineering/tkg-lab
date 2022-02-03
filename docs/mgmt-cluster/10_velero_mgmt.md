# Install Velero and Setup Nightly Backup on Management Cluster

## Overview

At this time the management cluster can not be managed by Tanzu Mission Control, and thus can't manage it's Data Protection as it does for our shared services cluster.  However, under TMC leverages velero under the covers, so we can take on the data protection configuration ourself.

## Install Velero client

It is assumed you have already downloaded velero cli from [Enable Data Protection and Setup Nightly Backup for Shared Services Cluster](../shared-services-cluster/09_velero_ssc.md).

## Target Locations

Your backup will be stored based upon the IaaS you are using.

- `vSphere` will target the Minio server you deployed
- `Azure` will create a storage account in your cluster resource group and backups will go there
- `AWS` will go into AWS S3 and backups will go there

Credentials to access the target storage location are stored at `generated/$CLUSTER_NAME/velero/velero-credentials`.

If using Cloud Gate for AWS, no credentials will be stored and you will use the IAM of the node.

## Set configuration parameters

The scripts to prepare the YAML to deploy velero depend on a parameters to be set.  Ensure the following are set in `params.yaml` based upon your environment:

```yaml
velero.bucket: my-bucket
```

## Prepare Manifests and Deploy Velero

Prepare the YAML manifests for the related velero K8S objects and then run the following script to install velero and configure a nightly backup.

```bash
./scripts/velero.sh $(yq e .management-cluster.name $PARAMS_YAML)
```

## Validation Step

Ensure schedule is created and the first backup is starting

```bash
velero schedule get
velero backup get | grep daily
```

## Go to Next Step

Now management cluster steps are complete, on to the workload cluster.

[Create new Workload Cluster](../workload-cluster/01_install_tkg_and_components_wlc.md)
