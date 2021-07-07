# Tanzu Observability by WaveFront

You'll need a Wavefront url and API_KEY to integrate the clusters with Wavefront.

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

## Configuration through Tanzu Mission Control (TMC)

TMC allows you to directly integrate with Tanzu Observability for clusters under management.  This is a new feature for TMC and is only available through the UI.  CLI integration is targeted for Q2 2021.  As such, we don't have have a scripted option.

1. Log-in to TMC
2. Select your cluster from the cluster list
3. Choose Actions->Tanzu Observability by Wavefront->Add...
4. Add dialog. Either select existing TO credential from drop down or setup a new credential. To setup a new credentrial; for `Tanzu Observability URL` enter the result of `echo $(yq r $PARAMS_YAML wavefront.url)`.  For `Tanzu Observability API token` enter the result of `echo $(yq r $PARAMS_YAML wavefront.api-key)` and then click `CONFIRM` button.
5. It should take about 2 minutes to complete enablement of the cluster, and then a little more to see the data flowing in Tanzu Observability.

**Validation**

1. You have a new namespace created: `tanzu-observability-saas`

```bash
kubectl get all -n tanzu-observability-saas
```

2. Test it out.  Choose Actions->Tanzu Observability by Wavefront->Open Tanzu Observability by Wavefront.  A new browser tab will open directly on the Kubernetes Cluster Dashboard.  Your cluster will be named as named $CLUSTER_NAME.attached.attached

