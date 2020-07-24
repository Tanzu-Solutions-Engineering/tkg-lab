# Install Kubeapps

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
kubeapps:
  fqdn: kubeapps.<shared-cluster domain name>
```

### Change to Shared Services Cluster
Kubeapps should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related kubeapps K8S objects.  Manifest will be output into `kubeapps/generated/` in case you want to inspect.
```bash
./kubeapps/00-generate_yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

### Create Kubeapps namespace
Create the kubeapps namespace.
```bash
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
```

### Add helm repo and install kubeapps
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install kubeapps --namespace kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
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
1. Open a browser and navigate to https://<$KUBEAPPS_FQDN>.  
```bash
open https://$(yq r $PARAMS_YAML kubeapps.fqdn)
```

## Okta Integration

### Admin 

1. Log into your Okta account you created as part of the [Okta Setup Lab](../mgmt-cluster/04_okta_mgmt.md).  The URL should be in your `params.yaml` file under okta.auth-server-fqdn.

2. Choose Directory (top menu) > Click Add Group > Enter: kubeapps-operator > Click Add Group.

3. Click on the kubeapps-operator group > Click Manage People > Click the Names of anyone you want with too have Admin status in Kubeapps > Click Save

4. Add kubeapps-operator to ClusterRoleBinding for cluster.admin (This isn't a best practice, but is easiest for a demo).
   Run:
```bash
./scripts/tmc-policy.sh $(yq r $PARAMS_YAML shared-services-cluster.name) cluster.admin kubeapps-operator
```

### Users

TBD
