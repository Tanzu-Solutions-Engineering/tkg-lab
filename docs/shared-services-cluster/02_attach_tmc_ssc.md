# Attach Shared Services Cluster to TMC

We want to have all kubernetes cluster under TMC management.  As such, execute the following script to attach your cluster to TMC.

>Note: The script leverages values specified in your params.yaml file to use for the cluster name and cluster group.

```bash
./scripts/tmc-attach.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes to appear clean.

In the Cluster view, go to `Add-ons > Tanzu Repositories` and disable the `tanzu-standard` repository if using version `v2023.7.13_update.2`
<img src="tanzu-repo.png" width="1000"><br>

## Go to Next Step

[Set policy on Shared Services Cluster](03_policy_ssc.md)
