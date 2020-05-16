# Create TKG Workload Cluster Setup


#### Note:
Make sure you have params.yml file already updated with all required parameters.

## Option 1 - Consolidated Script

If you want to create `workload cluster`, deploy `contour`, `gangway` and `fluent-bit` then execute below script otherwise go to option 2.

```bash
./workload-cluster-setup/scripts/build_wl.sh
```

## Option 2 - Individual Scripts

### Create Workload Cluster

```bash
./workload-cluster-setup/scripts/01-create-workload-cluster.sh
```

###### Validate the TKG management-cluster installation
```bash
tkg get cluster --config ./k8/config.yaml
```

![shared-cls-1](../img/work-cls-1.png)


Continue to Next Step: [Configure TMC](01a-configure-tmc.md)
