
### Deploy External DNS
Below script installs External DNS.

## AWS

```bash
./workload-cluster-setup/aws/scripts/03a-install-external-dns.sh
```

## vSphere

#### Install Metallb first

```bash
./workload-cluster-setup/vsphere/scripts/03-install-metallb.sh
```

```bash
./workload-cluster-setup/vsphere/scripts/04a-install-external-dns.sh
```
Continue to Next Step: [Configure Contour](04_configure_contour.md)
