# Set policy on Shared Services Cluster

## Setup Access Policy for platform-team to have cluster.admin role

```bash
./scripts/tmc-policy.sh \
  $(yq e .shared-services-cluster.name $PARAMS_YAML) \
  cluster.admin \
  platform-team
```

### Validation Step

1. Access TMC UI
2. Select Policies on the left nav
3. Choose Access->Clusters and then select your shared services cluster
4. Observe direct Access Policy => Set cluster.admin permission to the platform-team group

## Go to Next Step

[Install Contour on Shared Services Cluster](04_contour_ssc.md)
