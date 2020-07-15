# Attach Management Cluster to TMC

## Verify Active TMC Context

The following scripts assume that you have an active `tmc` cli session.  In order to test this, execute `tmc system context current` command to retrieve current context.  If you don't have an active session, login using `tmc login` command.

## Set configuration parameters

The scripts to attach the cluster to TMC depend on a parameters to be set.  The script will create the named cluster group if it does not already exist. Ensure the following are set in `params.yaml`:

```yaml
tmc.cluster-group: foo-cluster-group
```

## Attach Cluster to TMC

We want to have all kubernetes cluster under TMC management.  As such, execute the following script to attach your cluster to TMC.

> The script leverages values specified in your params.yaml file to use for the cluster name and cluster group

```bash
./scripts/tmc-attach.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes to appear clean.

## Go to Next Step

[Configure DNS and Prep Certificate Signing](03_dns_certs_mgmt.md)
