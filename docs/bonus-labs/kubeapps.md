# Install Kubeapps

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
kubeapps:
  server-fqdn: kubeapps.<shared-cluster domain name>
```

### Change to Shared Services Cluster
Kubeapps should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related kubeapps K8S objects.  Manifest will be output into `generated/$CLUSTER_NAME/kubeapps/` in case you want to inspect.
```bash
./kubeapps/00-generate_yaml.sh
```

### Create Kubeapps namespace
Create the kubeapps namespace.
```bash
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
```

### Modify Dex Configuration
Modify Dex Configuration
```bash
./scripts/inject-dex-client-kubeapps.sh
```

### Add helm repo and install kubeapps
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install kubeapps --namespace kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
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