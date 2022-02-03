# Enable Data Protection and Setup Nightly Backup on Shared Services Cluster

## Install Velero client

Even though Tanzu Mission Control will manage your data protection amd lifecycle velero on the cluster, at times it may be useful to have the velero cli.

Download and install the Velero cli from TKG 1.5.0 at https://www.vmware.com/go/get-tkg.

## Set configuration parameters

The scripts to prepare the YAML to deploy velero depend on a parameters to be set.  Ensure the following are set in `params.yaml` based upon your environment.  This should be the target location you created above

```yaml
tmc.data-protection-backup-location-name: my-tmc-data-protection-target-location
velero.bucket: velero-backups
```

## Setup Your Data Protection Target

We will place our TMC Data Protection backups in the Minio server we deployed.

Follow the Tanzu Mission Control docs:

- [Create a Account Credential](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-30DAD680-FA77-48E3-990B-1DFC250372FA.html).  Again, this is IaaS dependent.  For AWS you will provide your S3 credentials. For vSphere your Minio account credentials.  For Azure, your Azure Blob Storage credentials.
- [Create a Target Location](https://docs.vmware.com/en/VMware-Tanzu-Mission-Control/services/tanzumc-using/GUID-867683CE-8AF0-4DC7-9121-81AD507EDB3B.html?hWord=N4IghgNiBcIC5gE4HMCmcAEED2BjMcAltgHYDOIAvkA) with your IaaS dependent target location.  **You must set your bucket name to match `velero.bucket` in the parmams.yaml file**

## Enable Data Protection on Your Cluster

Orchestrate commands for the `tmc` cli to enable data protection on the cluster and then setup a daily backup.

```bash
./scripts/dataprotection.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Validation Step

Ensure schedule is created and the first backup is starting

```bash
velero schedule get
velero backup get | grep daily
```

## Go to Next Step

[Install Harbor](../shared-services-cluster/10_harbor.md)
