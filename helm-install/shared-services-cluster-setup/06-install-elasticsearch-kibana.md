# Install elasticsearch and kibana

Run the below command which will install Elastic Seach and Kibana

## AWS

```bash
./shared-services-cluster-setup/aws/scripts/06-install-elasticsearch-kibana.sh
```

## vSphere

```bash
./shared-services-cluster-setup/vsphere/scripts/07-install-elasticsearch-kibana.sh
```

To Validate, browse to the Kibana url which is provided in the `params.yml`.

It should be something similar to: kibana.svc.tkg.lab.your-domain


![mgmt-cls-2](../img/shared-cls-9.png)


Continue to Next Step: [Configure FluentBit](07-install-fluent-bit.md)
