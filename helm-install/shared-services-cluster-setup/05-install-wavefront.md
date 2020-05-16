# Deploy WaveFront

Run the below command which will install the Wavefront Helm chart and configure it the the wavefront api token you provided.

```bash
./shared-services-cluster-setup/scripts/05-install-wavefront.sh
```

## Access wavefront

https://surf.wavefront.com and filter the cluster list to your $VMWARE_ID-service-cluster-name.


![mgmt-cls-2](../img/shared-cls-8.png)

Continue to Next Step: [Configure Elastic Search & Kibana](06-install-elasticsearch-kibana.md)
