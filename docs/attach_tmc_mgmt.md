# Attach Management Cluster to TMC

```bash
export VMWARE_ID=YOUR_ID
tmc cluster attach \
  --name se-$VMWARE_ID-mgmt \
  --labels origin=$VMWARE_ID \
  --group se-$VMWARE_ID-dev-cg \
  --output clusters/mgmt/sensitive/tmc-mgmt-cluster-attach-manifest.yaml
kubectl apply -f clusters/mgmt/sensitive/tmc-mgmt-cluster-attach-manifest.yaml
```

## Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes but appear clean.