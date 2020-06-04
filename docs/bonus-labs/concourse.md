# Concourse for CI/CD

In this lab we will install Concourse to the shared services cluster via a Helm chart.  The following modifications to the default chart values need to be made:
- Use Contour Ingress
- Generate certificate via Let's Encrypt
- Updated URLs 

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
concourse:
  namespace: concourse
  url: concourse.tkg-shared.<your domain>
```

### Change to Shared Services Cluster
Concourse should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r params.yaml shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related Harbor K8S objects.  Manifest will be output into `harbor/generated/` in case you want to inspect.
```bash
./harbor/00-generate_yaml.sh
```
### Create Concourse namespace and prepare deployment file
Create the Concourse namespace and generate the deployment file.  This file (generated/tkg-shared/concourse/concourse-values-contour.yaml) will contain oeverrides to the default chart values.
.
```bash
CONCOURSE_NAMESPACE=$(yq r params.yaml concourse.namespace)
kubectl create ns $CONCOURSE_NAMESPACE

./scripts/generate-concourse.sh
```

### Add helm repo and install Concourse
Add the repository to helm and use the generated deployment file to deploy the chart.

```bash
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm upgrade --install concourse concourse/concourse --values generated/tkg-shared/concourse/concourse-values-contour.yaml -n $CONCOURSE_NAMESPACE
```

## Validation Step
1. All Concourse pods are in a running state:
```bash
kubectl get po -n $CONCOURSE_NAMESPACE
```
2. Certificate is True and Ingress created:
```bash
kubectl get cert,ing -n $CONCOURSE_NAMESPACE
```
2. Open a browser and navigate to https://<Concourse URL>.  The default user is test/test.  This can be controlled by editing the deployment values.

