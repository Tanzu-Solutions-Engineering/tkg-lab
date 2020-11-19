# Concourse for CI/CD

In this lab we will install Concourse to new worker nodes within the shared cluster via a Helm chart.  The following modifications to the default chart values need to be made:
- Use Contour Ingress
- Generate certificate for concourse web endpoint via Cert Manager/Let's Encrypt
- Updated URLs for concourse web
- Set an admin user with password from `params.yaml` and place in main team
- Configure for OIDC authentication and initial placement of `platform-team` into the main team
- Tolerations so that concourse web and workers run on isolated tainted nodes
- Explicitly add Let's Encrypt CA to the OIDC endpoint in case of custom Okta domains

Concourse will also be managed via Tanzu Mission Control in a dedicated workspace.

## Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
concourse:
  namespace: concourse
  fqdn: concourse.tkg-shared.<your-domain>
  tmc-workspace: concourse-workspace
  admin-password: SuperSecretPassword
okta:
  concourse-app-client-id: foo-client-id
  concourse-app-client-secret: bar-client-secret
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
tmc cluster namespace create -c $VMWARE_ID-$CLUSTER_NAME-$IAAS -n $CONCOURSE_NAMESPACE -d "Concourse product installation" -k $CONCOURSE_TMC_WORKSPACE -m attached -p attached
```

## Prepare Okta for Concourse Client

1. Log into your Okta account you created as part of the [Okta Setup Lab](../mgmt-cluster/04_okta_mgmt.md).  The URL should be in your `params.yaml` file under okta.auth-server-fqdn.

2. Choose Applications (top menu) > Add Application > Create New App > Web, Click Next.

3. Complete the form as follows, and then click Done.
  - Give your app a name: `Concourse`
  - Remove Base URL
  - Login redirect URIs: `https://<concourse.fqdn from $PARAMS_YAML>/sky/issuer/callback` #
  - Logout redirect URIs: `https://<concourse.fqdn from $PARAMS_YAML>/sky/issuer/logout`
  - Grant type allowed: `Authorization Code`

3. Capture `Client ID` and `Client Secret` for and put it in your $PARAMS_YAML file

```yaml
okta:
  concourse-app-client-id: MY_CLIENT_ID
  concourse-app-client-secret: MY_CLIENT_SECRET
```

4. On the top left, Choose the arrow next to Developer Console and choose `Classic UI`

5. Choose Applications (top menu) > Applications > Pick your app > Sign On tab > Edit **OpenID Connect ID Token** section
  - Groups claim type => `Filter`
  - Groups claim filter => **groups** Matches regex **.\***

## Prepare Manifests and Deploy Concourse
 Prepare and deploy the YAML manifests for the related Concourse K8S objects.  Manifest will be output into `concourse/generated/` in case you want to inspect.

```bash
./scripts/generate-and-apply-concourse-yaml.sh
```

## Manage the Concourse team namespace with TMC
Lastly, add the newly created namespace for the Concourse main team to TMC's managed workspace we created earlier.

```bash
tmc cluster namespace attach -c $VMWARE_ID-$CLUSTER_NAME-$IAAS -n concourse-main -k $CONCOURSE_TMC_WORKSPACE -m attached -p attached
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
3. Open a browser and navigate to the FQDN you defined for Concourse above.  The default user is admin/<password from `params.yaml`>.

## Login via Fly CLI

1. Download the fly cli from the concourse UI.  Choose the correct OS version and then copy to location in your path (e.g. `/usr/local/bin`).

2. Log in and save alias

```bash
fly -t $(yq r $PARAMS_YAML shared-services-cluster.name) login \
  -c https://$(yq r $PARAMS_YAML concourse.fqdn) \
  -n main 
```

>Note: You will be prompted to access the web url and authenticate.  If you are running fly from a console that does not have web app access, you can alternatively pass in the username and password into the login command for the admin user (not the OIDC users).

## Create Sample Pipeline

There are a number of ways to manage pipeline configuration values.  See notes at ...  In the sample pipeline we will place them in a Kubernetes secret.

1. Create Kubernetes secret in the concourse_main namespace.

```bash
ytt -f concourse/common-secrets.yaml --ignore-unknown-comments | kapp deploy -n concourse-main -a concourse-main-secrets -y -f -
```

2. Set the pipeline using fly cli

```bash
fly -t $(yq r $PARAMS_YAML shared-services-cluster.name) set-pipeline -p test-pipeline -c concourse/test-pipeline.yaml -n
fly -t $(yq r $PARAMS_YAML shared-services-cluster.name) unpause-pipeline -p test-pipeline
fly -t $(yq r $PARAMS_YAML shared-services-cluster.name) trigger-job -j test-pipeline/hello-world --watch
```
