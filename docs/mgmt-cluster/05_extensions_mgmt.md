# Retrieve TKG Extensions

The TKG Extensions bundle is available for download from the [same location](https://my.vmware.com/en/web/vmware/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/1_x) where you download the TKG CLI.

Follow [the documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.2/vmware-tanzu-kubernetes-grid-12/GUID-extensions-index.html) to unpack the bundle for instructions on how to install the in-cluster/shared services.
```bash
tar -xzf tkg-extensions-manifests-v1.2.0-vmware.1.tar-2.gz
 mv tkg-extensions-v1.2.0+vmware.1 tkg-extensions/
```

Also make sure to install the Carvel tools bundled in the TKG artifact.

## Go to Next Step

[Install Contour Ingress Controller](06_contour_mgmt.md)
