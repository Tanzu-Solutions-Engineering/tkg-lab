# Install Tanzu Observability by WaveFront on the management cluster

Use your Pivotal Okta to get into wavefront, and then retrieve your API_KEY.
Assuming you have helm3 installed.

```bash
export TO_API_KEY=YOUR_API_KEY
export VMWARE_ID=YOUR_VMWARE_ID
kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm install wavefront wavefront/wavefront -f clusters/mgmt/wavefront/wf.yml \
  --set wavefront.url=https://surf.wavefront.com \
  --set wavefront.token=$TO_API_KEY \
  --set clusterName=$VMWARE_ID-mgmt \
  --namespace wavefront
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID-mgmt cluster.