# Set policy on Workload Cluster and Namespace

## Setup Access Policy for platform-team to have cluster.admin role

```bash
./scripts/tmc-policy.sh \
  $(yq r params.yaml shared-services-cluster.name) \
  cluster.admin \
  platform-team
```

### Validation Step

1. Access TMC UI
2. Select Policies on the left nav
3. Choose Access->Clusters and then select your wlc-1 cluster
4. Observe direct Access Policy => Set cluster.admin permission to the platform-team group

## Go to Next Step

[Install Contour Ingress Controller](docs/workload-cluster/04_contour_ssc.md)