# Install GitLab


### Change to Shared Services Cluster
gitlab should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related gitlab K8S objects.  Manifest will be output into `gitlab/generated/` in case you want to inspect.
```bash
./gitlab/00-generate_yaml.sh
```

### Create gitlab namespace
Create the gitlab namespace.
```bash
kubectl apply -f generated/$CLUSTER_NAME/gitlab/01-namespace.yaml
```

### Add helm repo and install gitlab
```bash
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab -f ./gitlab-values.yaml --namespace gitlab
```

## Validation Step
1. All gitlab pods are in a running state:
```bash
kubectl get po -n gitlab
```
2. Certificates are True and Ingress resources created:
```bash
kubectl get cert,ing -n gitlab
```
3. Open a browser and navigate to https://<$gitlab_FQDN>.  
```bash
open https://gitlab.$(yq r $PARAMS_YAML shared-services-cluster.name).$(yq r $PARAMS_YAML subdomain)
```

## Okta Integration

### Admin 

TBD

