# Concourse for CI/CD

In this lab we will install Concourse to new worker nodes within the shared cluster via a Helm chart.  The following modifications to the default chart values need to be made:
- Use Contour Ingress
- Generate certificate via Let's Encrypt
- Updated URLs 

Concourse will also be managed via Tanzu Mission Control in a dedicated workspace.

## Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
concourse:
  namespace: concourse
  fqdn: concourse.tkg-shared.<your-domain>
  tmc-workspace: concourse-workspace
```

Once these are in place and correct, run the following to export the following into your shell:

```bash
export TMC_CLUSTER_GROUP=$(yq r $PARAMS_YAML tmc.cluster-group)
export CONCOURSE_NAMESPACE=$(yq r $PARAMS_YAML concourse.namespace)
export CONCOURSE_TMC_WORKSPACE=$TMC_CLUSTER_GROUP-$(yq r $PARAMS_YAML concourse.tmc-workspace)
export CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
export IAAS=$(yq r $PARAMS_YAML iaas)
export VMWARE_ID=$(yq r $PARAMS_YAML vmware-id)
```

## Scale Shared Cluster and Taint Nodes
Rather than creating a new cluster, which we normally would recommend for Concourse, to save on resources we can create a couple of worker nodes in our shared cluster and taint them.  What this does is enable us to use these new nodes exclusively for Concourse.  The Concourse web and worker pods will be given a toleration for the taint, and use node selectors to ensure that they are "pinned" to the new cluster worker nodes.  To do this, we will:
- Scale the Shared Services cluster
- Label the new nodes 
- Taint the labelled nodes to prevent any other workload from running there
- Apply the toleration and node selector to the Concourse Helm chart

First, create a pair of new worker nodes in the tkg cluster:

```bash
NEW_NODE_COUNT=$(($(yq r $PARAMS_YAML shared-services-cluster.worker-replicas) + 2))
tkg scale cluster $CLUSTER_NAME -w $NEW_NODE_COUNT
```
After a few minutes, check to see which new nodes were created.  These will be the nodes that are the most recent in the AGE output of "kubectl get nodes".  Label these nodes using a space to separate the list of nodes in the command:

```bash
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
kubectl get nodes
kubectl label nodes ip-10-0-0-57.us-east-2.compute.internal ip-10-0-0-105.us-east-2.compute.internal type=concourse
```

Now add the taint to the same nodes.  This will prevent other workloads from being scheduled on the new nodes.  Note that any DaemonSet may still have a pod running on these nodes because the taint was not added until after node creation.

```bash
kubectl taint nodes -l type=concourse type=concourse:PreferNoSchedule --overwrite
``` 
## Create Concourse Namespace
In order to deploy the Helm chart for Concourse to a dedicated namespace, we need to create it first.  To do this, we can use Tanzu Mission Control, as it is already running on our shared services cluster.  This will create a "managed namespace", where we can assert additional control over what is deployed.  

```bash
tmc workspace create -n $CONCOURSE_TMC_WORKSPACE -d "Workspace for Concourse"
tmc cluster namespace create -c $VMWARE_ID-$CLUSTER_NAME-$IAAS -n $CONCOURSE_NAMESPACE -d "Concourse product installation" -k $CONCOURSE_TMC_WORKSPACE
```
## Prepare Manifests and Deploy Concourse
 Prepare and deploy the YAML manifests for the related Concourse K8S objects.  Manifest will be output into `concourse/generated/` in case you want to inspect.

```bash
./scripts/generate-and-apply-concourse-yaml.sh
```

## Manage the Concourse team namespace with TMC
Lastly, add the newly created namespace for the Concourse main team to TMC's managed workspace we created earlier.

```bash
tmc cluster namespace attach -c $VMWARE_ID-$CLUSTER_NAME-$IAAS -n concourse-main -k $CONCOURSE_TMC_WORKSPACE
```
## Validation Step
1. All Concourse pods are in a running state, on the tainted nodes:
```bash
kubectl get po -n $CONCOURSE_NAMESPACE -o wide
```
2. Certificate is True and Ingress created:
```bash
kubectl get cert,ing -n $CONCOURSE_NAMESPACE
```
3. Open a browser and navigate to the FQDN you defined for Concourse above.  The default user is test/test.  This can be controlled by editing the deployment values.

