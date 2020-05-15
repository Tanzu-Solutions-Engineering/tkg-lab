# Retrieve TKG Extensions

The TKG Extensions bundle is available for download from the [same location](https://my.vmware.com/en/web/vmware/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/1_x) where you download the TKG CLI.

Follow [the documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.0/vmware-tanzu-kubernetes-grid-10/GUID-manage-instance-index.html#unpack-bundle) to unpack the bundle for instructions on how to install the in-cluster/shared services.
```bash
tar -xzf  tkg-extensions-manifests-v1.0.0_vmware.1.tar.gz
mv tkg-extensions-v1.0.0 tkg-extensions
```

> Note: v1.0.0 has a spelling error one of the yaml files that needs to be fixed.  `tkg-extensions/authentication/gangway/aws/06-deployment.yaml`.  Search for `sesssionKey` and replace it with `sessionKey`.

## Go to Next Step

[Install Contour Ingress Controller](docs/mgmt-cluster/06_contour_mgmt.md)
