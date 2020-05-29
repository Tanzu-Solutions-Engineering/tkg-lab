# Install Harbor Image Registry

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
harbor:
  harbor-cn: harbor.<shared-cluster domain name>
  notary-cn: notary.<shared-cluster domain name>
```

### Change to Shared Services Cluster
Harbor Registry should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r params.yaml shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related Harbor K8S objects.  Manifest will be output into `harbor/generated/` in case you want to inspect.
```bash
./harbor/00-generate_yaml.sh
```
### Create Create Harbor namespace and certs
Create the Harbor namespace and certificate.  Wait for the certificate to be ready.
```bash
kubectl apply -f harbor/generated/01-namespace.yaml
kubectl apply -f harbor/generated/02-certs.yaml  
watch kubectl get certificate -n harbor
```

### Add helm repo and install harbor
```bash
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor -f harbor/generated/harbor-values.yaml --namespace harbor
```

## Validation Step
1. All harbor pods are in a running state:
```bash
kubectl get po -n harbor
```
2. Open a browser and navigate to https://<$HARBOR_CN>.  The default user is admin and pwd is Harbor12345
