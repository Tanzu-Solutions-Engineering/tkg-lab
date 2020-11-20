# Retrieve TKG Extensions

The TKG Extensions bundle is available for download from the [same location](https://www.vmware.com/go/get-tkg) where you download the TKG CLI.

Follow [the documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.2/vmware-tanzu-kubernetes-grid-12/GUID-extensions-index.html) to unpack the bundle for instructions on how to install the in-cluster/shared services.
```bash
gunzip ~/Downloads/tkg-extensions-manifests-v1.2.0-vmware.1.tar-2.gz
tar -xzf ~/Downloads/tkg-extensions-manifests-v1.2.0-vmware.1.tar-2
mv tkg-extensions-v1.2.0+vmware.1 tkg-extensions
```

Also make sure to install the Carvel tools bundled in the TKG artifact.

## Go to Next Step

[Install Contour Ingress Controller](06_contour_mgmt.md)
