
### Deploy Contour
Below script is going to deploy contour. External DNS is going to create a wild card A record for envoy service.

## AWS
```bash
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/02-install-contour.sh
```

## vSphere
```bash
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/03-install-contour.sh
```

###### Validate Contour Installation
```bash
kubectl get all -n tanzu-system-ingress
```
![mgmt-cls-2](../../img/mgmt-cls-2.png)

This will also add a `CNAME` entry in AWS Hosted zone which you created earlier. The `CNAME` will be mapped to AWS load balancer.

Example: Example: *.mgmt.tkg.lab.your-domain

Continue to Next Step: [Configure Dex](04_install_dex.md)
