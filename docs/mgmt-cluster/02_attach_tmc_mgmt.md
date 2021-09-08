# Register Management Cluster to TMC

## Verify Active TMC Context

The following scripts assume that you have an active `tmc` cli session.  In order to test this, execute `tmc system context current` command to retrieve current context.  If you don't have an active session, login using `tmc login` command.

## Register Management Cluster

>Note: Registering management clusters is currently only supported for TKG on vSphere and Azure.  TKG on AWS is coming soon.

Execute the following script to register your TMC management cluster.  It will create a cluster group as defined in `.tmc.cluster-group` in `params.yaml`.  Then it will use the tmc cli to regiter the management cluster.

```bash
./scripts/tmc-register-mc.sh
```

## Validation Step

Go to the TMC UI and find your management.  On the left, choose Administration, then Management Clusters in top nav, and choose your management cluster.

## Additional Notes

- This lab does not leverage the workload cluster lifecycle management capabilities of TMC due to historical reasons

## Go to Next Step

[Configure DNS and Prep Certificate Signing](03_dns_certs_mgmt.md)
