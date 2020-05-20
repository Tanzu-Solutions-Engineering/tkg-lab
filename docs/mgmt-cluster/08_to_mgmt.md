# Install Tanzu Observability by WaveFront on the management cluster

You'll need a Wavefront API_KEY to integrate thee cluster with Wavefront.
If you have access to Pivotal Okta then use it to get into wavefront, and then retrieve your API_KEY.

Assuming you have helm3 installed, run this script:

```bash
./scripts/deploy-wavefront.sh $(yq r params.yaml management-cluster.name)
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID-mgmt cluster.

## Go to Next Step

[Install Tanzu Observability](docs/mgmt-cluster/08_to_mgmt.md)