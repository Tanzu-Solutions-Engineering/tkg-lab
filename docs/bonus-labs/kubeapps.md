# Install Kubeapps

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
kubeapps:
  server-fqdn: kubeapps.<workload-cluster domain name>
```

## Prepare Manifests and Deploy Kubeapps
Kubeapps should be installed in the workload cluster, as it is going to be available to all users. Prepare and deploy the YAML manifests for the related kubeapps K8S objects.  Manifest will be output into `generated/$CLUSTER_NAME/kubeapps/` in case you want to inspect.
```bash
./kubeapps/generate-and-apply-kubeapps-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)
```

## Validation Step
1. All kubeapps pods are in a running state:
```bash
kubectl get po -n kubeapps
```
2. Certificate is True and Ingress created:
```bash
kubectl get cert,ing -n kubeapps
```
3. Open a browser and navigate to https://<$KUBEAPPS_FQDN>.  
```bash
open https://$(yq r $PARAMS_YAML kubeapps.server-fqdn)
```
4. Login as `alana`, who is an admin on the cluster.  You should be taken to the kubeapps home page