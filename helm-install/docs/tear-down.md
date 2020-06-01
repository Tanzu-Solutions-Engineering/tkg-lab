# TKG - HOL Cleanup

#### Note:

Delete Workload cluster

```bash
./workload-cluster-setup/common/scripts/delete-cluster.sh
```

Delete Shared Services cluster

```bash
./shared-services-cluster-setup/common/scripts/delete-cluster.sh
```

Delete Workload cluster

## AWS

```bash
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/delete-cluster.sh
```

## vSphere

```bash
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/delete-cluster.sh
```

You might have to do some minor manual cleanups through AWS Console.
