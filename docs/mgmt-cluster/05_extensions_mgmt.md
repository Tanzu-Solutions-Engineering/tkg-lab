# Retrieve TKG Extensions

The TKG Extensions bundle is available for download from the [same location](https://www.vmware.com/go/get-tkg) where you download the TKG CLI.

Follow [the documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-extensions-index.html) to unpack the bundle for instructions on how to install the in-cluster/shared services.
```bash
rm -rf tkg-extensions
gunzip ~/Downloads/tkg-extensions-manifests-v1.3.0+vmware.1.tar.gz
tar -xzf ~/Downloads/tkg-extensions-manifests-v1.3.0+vmware.1.tar
mv tkg-extensions-v1.3.0+vmware.1 tkg-extensions
# Optionally run this if your working with a version of the extensions manifests prior to RTM or GA
cd tkg-extensions
# On Mac
find ./ -type f -exec sed -i '' 's/projects.registry.vmware.com/projects-stg.registry.vmware.com/' {} \;
# On Linux
grep -rli 'projects.registry.vmware.com' * | xargs -i@ sed -i "s/projects.registry.vmware.com/projects-stg.registry.vmware.com/g" @
```

Also make sure to install the Carvel tools bundled in the TKG artifact.

## Go to Next Step

[Install Contour Ingress Controller](06_contour_mgmt.md)
