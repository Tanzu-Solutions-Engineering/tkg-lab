# Gitlab for CI/CD

In this lab we will install Gitlab to the shared cluster via a Helm chart.  The following modifications to the default chart values need to be made:
- Use Contour Ingress
- Generate certificate via Let's Encrypt
- Updated URLs 
- Scaled down Gitlab resources

Gitlab will also be managed via Tanzu Mission Control in a dedicated workspace.

## Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
gitlab:
  namespace: gitlab
  tmc-workspace: gitlab-workspace
```

Once these are in place and correct, run the following to export the following into your shell:

```bash
export TMC_CLUSTER_GROUP=$(yq r params.yaml tmc.cluster-group)
export GITLAB_NAMESPACE=$(yq r params.yaml concourse.namespace)
export GITLAB_TMC_WORKSPACE=$TMC_CLUSTER_GROUP-$(yq r params.yaml gitlab.tmc-workspace)
export CLUSTER_NAME=$(yq r params.yaml shared-services-cluster.name)
export IAAS=$(yq r params.yaml iaas)
export VMWARE_ID=$(yq r params.yaml vmware-id)
```
## Create Gitlab namespace and prepare deployment file
In order to deploy the Helm chart for Gitlab to a dedicated namespace, we need to create it first.  To do this, we can use Tanzu Mission Control, as it is already running on our shared services cluster.  This will create a "managed namespace", where we can assert additional control over what is deployed.  

NOTE: if you want to avoid using TMC, simply create the namespace in the shared-services cluster manually using "kubectl create namespace ${GITLAB_NAMESPACE}"

```bash
tmc workspace create -n $GITLAB_TMC_WORKSPACE -d "Workspace for Gitlab"
tmc cluster namespace create -c $VMWARE_ID-$CLUSTER_NAME-$IAAS -n $GITLAB_NAMESPACE -d "Gitlab product installation" -k $GITLAB_TMC_WORKSPACE
```

Generate the deployment file.  This file (generated/tkg-shared/gitlab/values-gitlab.yaml) will contain oeverrides to the default chart values.

```bash
./scripts/generate-gitlab.sh
```

## Add helm repo and install Gitlab
Add the repository to helm and use the generated deployment file to deploy the chart.

```bash
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab -f generated/tkg-shared/gitlab/values-gitlab.yaml -n $GITLAB_NAMESPACE
```

## Validation Step

Check to see if the pods, ingresses, and PVCs are up and running: 

```bash
kubectl get pod,pvc,ing,cert -n gitlab
kubectl get -n gitlab secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

Go to the browser and use the FQDN for Gitlab to test it out.
