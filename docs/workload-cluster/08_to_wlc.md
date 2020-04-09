# Install Tanzu Observability by WaveFront on the workload cluster

Use your Pivotal Okta to get into wavefront, and then retrieve your API_KEY.
Assuming you have helm3 installed.

```bash
export TO_API_KEY=YOUR_API_KEY
export VMWARE_ID=YOUR_VMWARE_ID
kubectl create namespace wavefront
helm install wavefront wavefront/wavefront \
  --set wavefront.url=https://surf.wavefront.com \
  --set wavefront.token=$TO_API_KEY \
  --set clusterName=$VMWARE_ID-wlc-1 \
  --namespace wavefront
```

## Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID-wlc-1 cluster.