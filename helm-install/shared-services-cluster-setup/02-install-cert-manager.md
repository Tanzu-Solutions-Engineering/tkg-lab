# Deploy cert-manager

Run the below command to install Cert Manager. Wait till all the objects are properly initialized

```bash
./shared-services-cluster-setup/scripts/02-install-certmanager.sh
```

###### Validate all the objects have been initialized.

    kubectl get all -n cert-manager

Continue to Next Step: [Configure Contour](03_configure_contour.md)
