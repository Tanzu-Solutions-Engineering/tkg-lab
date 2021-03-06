# Install Tanzu Observability by WaveFront on the Shared Services Cluster

You'll need a Wavefront *API Token* to integrate the cluster with Wavefront.  This can be gotten by logging into Wavefront -> Account -> API Access -> (Generate / Copy API Token) -> Insert into params.yaml.

Also note the url for wavefront.  If you are not using surf.wavefront.com, simply place what you are using into params.yaml:

```yaml
wavefront:
  api-key: <get from Wavefront account section>
  url: https://surf.wavefront.com. <<-- or switch to demo.wavefront.com if using that one
  cluster-name-prefix: <your VMWare ID>
```

NOTE: If you have access to Pivotal Okta, then use it to get into wavefront, and then retrieve your API Token for surf.wavefront.com.

Assuming you have helm3 installed, run this script:

```bash
./scripts/deploy-wavefront.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID clusters.

## Go to Next Step

[Enable Data Protection and Setup Nightly Backup](../shared-services-cluster/09_velero_ssc.md)
