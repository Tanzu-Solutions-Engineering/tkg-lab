# Set policy on Workload Cluster and Namespace

## Prepare Manifests and Execute Yaml

Prepare the YAML manifests for acme-fitness workspace and namespace for acme-fitness related to tmc.  Manifest will be output into `generated/$CLUSTER_NAME/tmc/` in case you want to inspect.

```bash
./scripts/generate-and-apply-tmc-acme-fitness-yaml.sh $(yq r params.yaml workload-cluster.name)
```

## Set Resource Quota for acme-fitness namespace

We want to limit the resources that acme-fitness team can consume on the cluster.  Use this script.

```bash
./scripts/apply-acme-fitness-quota.sh
```
