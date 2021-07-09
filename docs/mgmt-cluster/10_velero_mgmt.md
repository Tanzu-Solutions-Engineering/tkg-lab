# Install Velero and Setup Nightly Backup on Management Cluster

## Overview

At this time the management cluster can not be managed by Tanzu Mission Control, and thus can't manage it's Data Protection as it does for our shared services cluster.  However, under TMC leverages velero under the covers, so we can take on the data protection configuration ourself.

## Install Velero client

It is assumed you have already downloaded velero cli from [Enable Data Protection and Setup Nightly Backup for Shared Services Cluster](../shared-services-cluster/09_velero_ssc.md).

## Setup AWS as a target for backups

Follow [Velero Plugins for AWS Guide](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup).  I chose **Option 1** for **Set Permissions for Velero Step**.

Store your credentials-velero file in `keys/` directory.

Go to AWS console S3 service and create a bucket for cluster backups.

>Note: You will follow the process of using AWS for backups regardless of if your TKG clusters are deployed to Azure or vSphere.  Remember, this is just a lab, so we have simplified the variations.

## Set configuration parameters

The scripts to prepare the YAML to deploy velero depend on a parameters to be set.  Ensure the following are set in `params.yaml` based upon your environment:

```yaml
velero.bucket: my-bucket
veloreo.region: us-east-2
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
