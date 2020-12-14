# Attach Management Cluster to TMC

## Verify Active TMC Context

The following scripts assume that you have an active `tmc` cli session.  In order to test this, execute `tmc system context current` command to retrieve current context.  If you don't have an active session, login using `tmc login` command.

## NOOP

The remainder of this step is intentionally blank.  In the near future, TMC will be adding the ability to register a TKG management cluster so that it can drive the lifecycle of its workload clusters.  We are super excited for that feature set, until that time management clusters can not be attached to TMC.

## Go to Next Step

[Configure DNS and Prep Certificate Signing](03_dns_certs_mgmt.md)
