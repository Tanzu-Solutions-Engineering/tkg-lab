# Install Tanzu Observability by WaveFront on the management cluster

You'll need a Wavefront API_KEY to integrate thee cluster with Wavefront.
If you have access to Pivotal Okta then use it to get into wavefront, and then retrieve your API_KEY.

Assuming you have helm3 installed, run this script:

```bash
./scripts/deploy-wavefront.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID clusters.

## Go to Next Step

[Create new Shared Services Cluster](../shared-services-cluster/01_install_tkg_ssc.md)