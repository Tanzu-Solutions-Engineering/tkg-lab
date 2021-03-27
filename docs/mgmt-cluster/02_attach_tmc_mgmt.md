# Attach Management Cluster to TMC

## Verify Active TMC Context

The following scripts assume that you have an active `tmc` cli session.  In order to test this, execute `tmc system context current` command to retrieve current context.  If you don't have an active session, login using `tmc login` command.

## Attach Management Cluster to TMC

Run `scripts/tmc-mgmt-cluster-attach.sh` and verify that the management cluster `$VMWARE-ID-$MANAGEMENT_CLUSTER_NAME-$IAAS` was correctly attached in TSM.

## Go to Next Step

[Configure DNS and Prep Certificate Signing](03_dns_certs_mgmt.md)
