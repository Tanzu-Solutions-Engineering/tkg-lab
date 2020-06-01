# Create TKG Shared Service Cluster Setup

#### Note:
Make sure you have params.yaml file already updated with all required parameters.

## Option 1 - Consolidated Script

If you want to create `service cluster`, deploy `External DNS`, `contour`, `gangway`, `elasticsearch-kibana` and `fluent-bit` then execute below script otherwise go to option 2.

## AWS

```bash
./shared-services-cluster-setup/aws/scripts/build_svc.sh
```

## vSphere

```bash
./shared-services-cluster-setup/vsphere/scripts/build_svc.sh
```

## Option 2 - Individual Scripts

### Create Shared Services Cluster

## AWS

```bash
./shared-services-cluster-setup/aws/scripts/01-create-workload-cluster.sh
```

## vSphere

```bash
./shared-services-cluster-setup/vsphere/scripts/01-create-workload-cluster.sh
```


###### Validate the TKG management-cluster installation
```bash
tkg get cluster --config ./k8/config.yaml
```

![shared-cls-1](../img/shared-cls-1.png)


Continue to Next Step: [Configure TMC](01a-configure-tmc.md)
