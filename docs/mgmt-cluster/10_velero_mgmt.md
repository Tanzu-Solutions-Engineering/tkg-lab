# Install Velero and Setup Nightly Backup

**It is assumed you have already installed velero on the shared service cluster in [Install Velero and Setup Nightly Backup](docs/shared-services-cluster/9_velero_ssc.md) lab**

## Prepare Manifests and Deploy Velero

Prepare the YAML manifests for the related velero K8S objects and then run the following script to install velero and configure a nightly backup.

```bash
./scripts/velero.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Validation Step

Ensure schedule is created and the first backup is starting

```bash
velero schedule get
velero backup get | grep $(yq r $PARAMS_YAML management-cluster.name)
```

## Go to Next Step

Now management cluster steps are complete, on to the workload cluster.

[Create new Workload Cluster](../workload-cluster/01_install_tkg_and_components_wlc.md)