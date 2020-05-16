# Configure Ingress Controller

###### Below script is going to deploy contour and also create an A record in route53 for the envoy service.
```bash
./shared-services-cluster-setup/scripts/03-install-contour.sh
```

###### Validate Contour Installation
```bash
kubectl get all -n tanzu-system-ingress
```
![shared-cls-2](../img/shared-cls-2.png)

This will also add a `CNAME` entry in AWS Hosted zone which you created earlier. The `CNAME` will be mapped to AWS load balancer.

Example: *.svc.tkg.lab.your-domain


Continue to Next Step: [Configure Gangway](04_install_gangway.md)
