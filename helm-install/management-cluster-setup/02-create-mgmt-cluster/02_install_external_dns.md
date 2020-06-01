
### Deploy External DNS
Below script installs External DNS.

## AWS

```bash
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/02a-install-external-dns.sh
```

## vSphere

#### Install Metallb first
```bash
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/02-install-metallb.sh
```

```bash
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/03a-install-external-dns.sh
```
Continue to Next Step: [Configure Contour](03_configure_contour.md)
