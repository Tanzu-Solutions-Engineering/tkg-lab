# Enable Data Protection and Setup Nightly Backup

**It is assumed you have already completed the Enable Data Protection... lab on the shared service cluster in [Enable Data Protection and Setup Nightly Backup](docs/shared-services-cluster/9_velero_ssc.md) lab**

## Enable Data Protection on Your Cluster

Orchestrate commands for the `tmc` cli to enable data protection on the cluster and then setup a daily backup.

```bash
./scripts/dataprotection.sh $(yq r $PARAMS_YAML management-cluster.name)
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