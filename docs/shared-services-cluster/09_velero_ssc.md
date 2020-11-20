# Enable Data Protection and Setup Nightly Backup

## Install Velero client

Even though Tanzu Mission Control will manage your data protection amd lifecycle velero on the cluster, at times it may be useful to have the velero cli.

```bash
brew install velero
```

## Setup Your Data Protection Target

Follow the Tanzu Mission Control [docs](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-E728F568-5F1F-4963-A887-F09E2D19EA34.html) to create a data protection cloud provider account.

>Note: Do this step regardless if you are deploying TKG to vSphere or AWS.

## Set configuration parameters

The scripts to prepare the YAML to deploy velero depend on a parameters to be set.  Ensure the following are set in `params.yaml` based upon your environment:

```yaml
tmc.data-protection-backup-location-name: my-tmc-data-protection-account-name
```

## Enable Data Protection on Your Cluster

Orchestrate commands for the `tmc` cli to enable data protection on the cluster and then setup a daily backup.

```bash
./scripts/dataprotection.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

## Validation Step

Ensure schedule is created and the first backup is starting

```bash
velero schedule get
velero backup get | grep daily
```

## Go to Next Step

At this point the shared services cluster is complete.  Go back and complete the management cluster setup tasks.

[Install FluentBit](../mgmt-cluster/09_fluentbit_mgmt.md)