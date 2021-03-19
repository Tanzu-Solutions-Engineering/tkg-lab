# Set policy on Workload Cluster and Namespace

## Prepare Manifests and Execute Yaml

Prepare the YAML manifests for acme-fitness workspace and namespace for acme-fitness related to TMC.  Manifest will be output into `generated/$CLUSTER_NAME/tmc/` in case you want to inspect.

```bash
./scripts/generate-and-apply-tmc-acme-fitness-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)
```

## Set Resource Quota for acme-fitness namespace

We want to limit the resources that acme-fitness team can consume on the cluster.  Use this script.

```bash
./scripts/apply-acme-fitness-quota.sh
```

## Go to Next Step

[Log-in to workload cluster and setup kubeconfig](03-login-kubeconfig.md)
