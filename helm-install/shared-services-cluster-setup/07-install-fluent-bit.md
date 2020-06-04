# Install Fluent-bit

Run the below command to install fluent bit. Once installed it will start sending logs to ELK Stack.

## AWS

```bash
./shared-services-cluster-setup/aws/scripts/07-install-fluent-bit.sh
```

## vSphere

```bash
./shared-services-cluster-setup/vsphere/scripts/08-install-fluent-bit.sh
```

Once installed, go back to your kibana dashboard and configure with "logstash-*". You will see your cluster logs flowing throw.

![mgmt-cls-2](../img/shared-cls-10.png)


Back To [Home](../README.md)
