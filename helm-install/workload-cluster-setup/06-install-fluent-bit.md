# Install Fluent-bit

Run the below command to install fluent bit. Once installed it will start sending logs to ELK Stack.

Note: ELK stack is not installed on the workload cluster, but you can follow the same steps as done in Shared Cluster

## AWS

```bash
./workload-cluster-setup/aws/scripts/06-install-fluent-bit.sh
```

## vSphere

```bash
./workload-cluster-setup/vsphere/scripts/06-install-fluent-bit.sh
```

Continue to Next Step: [Install Wavefront](07-install-wavefront.md)
