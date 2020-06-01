# Deploy cert-manager

Run the below command to install Cert Manager. Wait till all the objects are properly initialized

## AWS
```bash
./shared-services-cluster-setup/aws/scripts/02-install-certmanager.sh
```

## vSphere
```bash
./shared-services-cluster-setup/vsphere/scripts/02-install-certmanager.sh
```

###### Validate all the objects have been initialized.

    kubectl get all -n cert-manager

Continue to Next Step: [Install External DNS](03_install_external_dns.md)
