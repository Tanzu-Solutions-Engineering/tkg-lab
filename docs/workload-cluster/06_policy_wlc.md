# Set policy on Workload Cluster and Namespace

## Set environment variables

The scripts to prepare the YAML depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# your vmware id
export VMWARE_ID=dpfeffer
```

## Setup Access Policy for platform-team to have cluster.admin role

```bash
tmc cluster iam add-binding se-$VMWARE_ID-wlc-1 --role cluster.admin --groups platform-team
```

### Validation Step

1. Access TMC UI
2. Select Policies on the left nav
3. Choose Access->Clusters and then select your wlc-1 cluster
4. Observe direct Access Policy => Set cluster.admin permission to the platform-team group
5. (Using Incognito Window) Login to the workload cluster at https://gangway.wlc-1.tkg-aws-lab.winterfell.live (adjust for your base domain)
6. Click Sign In
7. Log into okta as alana
8. Give a secret password
9. Download kubeconfig
10. Attempt to access wlc-1 cluster with the new config

```bash
KUBECONFIG=~/Downloads/kubeconf.txt kubectl get pods -A
```

## Prepare Manifests

Prepare the YAML manifests for the related tmc.  Manifest will be output into `tmc/` in case you want to inspect.

```bash
./scripts/generate-tmc-yaml.sh
```

## Use TMC to set workspace and Access Policy for acme-fitness

Use the commands below to create a workspace and associated namespace.  Then provide the workspace.edit role to the acme-fitness-dev group.

```bash
tmc workspace create -f tmc/config/workspace/acme-fitness-dev.yaml
tmc cluster namespace create -f tmc/config/namespace/tkg-mgmt-acme-fitness.yaml
tmc workspace iam add-binding $VMWARE_ID-acme-fitness-dev --role workspace.edit --groups acme-fitness-devs
```

## Set Resource Quota for acme-fitness namespace

```bash
kubectl apply -f clusters/wlc-1/acme-fitness-namespace-settings.yaml
```
