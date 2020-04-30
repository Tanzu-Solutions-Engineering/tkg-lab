# Attach the new workload cluster to TMC

NOTE: Please adjust the script below to accommodate your Cluster Group if you already had one created prior to starting this  lab.  

```bash
export VMWARE_ID=YOUR_ID
tmc cluster attach \
  --name se-$VMWARE_ID-wlc-1 \
  --labels origin=$VMWARE_ID \
  --group se-$VMWARE_ID-dev-cg \
  --output clusters/wlc-1/sensitive/tmc-wlc-1-cluster-attach-manifest.yaml
kubectl apply -f clusters/wlc-1/sensitive/tmc-wlc-1-cluster-attach-manifest.yaml
```

## Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes but appear clean.
