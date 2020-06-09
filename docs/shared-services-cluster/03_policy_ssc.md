# Set policy on Workload Cluster and Namespace

## Setup Access Policy for platform-team to have cluster.admin role

```bash
./scripts/tmc-policy.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  cluster.admin \
  platform-team
```

### Validation Step

1. Access TMC UI
2. Select Policies on the left nav
3. Choose Access->Clusters and then select your shared services cluster
4. Observe direct Access Policy => Set cluster.admin permission to the platform-team group

## Go to Next Step

[Install Contour Ingress Controller](04_contour_ssc.md)