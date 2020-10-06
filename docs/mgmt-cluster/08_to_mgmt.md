# Install Tanzu Observability by WaveFront on the management cluster

You'll need a Wavefront API_KEY to integrate thee cluster with Wavefront.
If you have access to Pivotal Okta then use it to get into wavefront, and then retrieve your API_KEY.

The scripts to prepare the YAML to deploy TO depend on a parameters to be set.  Ensure the following are set in `params.yaml`:

```yaml
wavefront:
  # Your API Key
  api-key: foo-bar-foo
  # References to your wavefront instance
  url: https://surf.wavefront.com
  # Prefix to add to all your clusters in wavefront
  cluster-name-prefix: dpfeffer
```

Assuming you have helm3 installed, run this script:

```bash
./scripts/deploy-wavefront.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID clusters.

## Optional Manual Configuration through Tanzu Mission Control (TMC)

TMC allows you to directly integrate with Tanzu Observability for clusters under management.  This is a new feature for TMC and is only available through the UI.  CLI integration is targeted for Q4 2020.  As such, the following is an option, but not the default as we can not script it.

1. Log-in to TMC
2. Select your management cluster from the cluster list: `echo $(yq r $PARAMS_YAML management-cluster.name)`
3. Choose Actions->Tanzu Observability by Wavefront->Add...
4. Add dialog.  For `Wavefront API URL` enter the result of `echo $(yq r $PARAMS_YAML wavefront.url)/api/`.  Notice the `/api/` addition to the name. For `Wavefront API token` enter the result of `echo $(yq r $PARAMS_YAML wavefront.api-key)` and then choose `Enable` button.
5. It should take about 2 minutes to complete enablement of the cluster, and then a little more to see the data flowing in Tanzu Observability.

**Validation**
1. You have a new namespace created: `tanzu-observability-saas`
```bash
kubectl get all -n ttanzu-observability-saas
```
2. Test it out.  Choose Actions->Tanzu Observability by Wavefront->Open Tanzu Observability by Wavefront.  A new browser tab will open directly on the Kubernetes Cluster Dashboard.  Your cluster will be named as named $CLUSTER_NAME.global.tmc

## Go to Next Step

[Create new Shared Services Cluster](../shared-services-cluster/01_install_tkg_ssc.md)