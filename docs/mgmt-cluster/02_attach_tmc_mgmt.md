# Attach Management Cluster to TMC

We want to have all kubernetes cluster under TMC management.  As such, execute the following script to attach your cluster to TMC.

> The script leverages values specified in your params.yaml file to use for the cluster name and cluster group

```bash
./scripts/tmc-attach.sh $(yq r params.yaml management-cluster.name)
```

## Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes to appear clean.

## Go to Next Step

[Configure DNS and Prep Certificate Signing](03_dns_certs_mgmt.md)
