# Create new workload cluster

Here we will deploy a new workload cluster for use as the shared services cluster.  All workload clusters will have similar steps for initial setup.

Here we are pulling the following values from the `params.yaml` file.  See examples

```yaml
# the DNS CN to be used for dex service
management-cluster.dex.fqdn: dex.mgmt.tkg-aws-lab.winterfell.live
shared-services-cluster.name: dorn
shared-services-cluster.worker-replicas: 2
iaas: aws
```

We need to copy the `oidc` script for the relevant iaas into our `.tkg` configuration directory so that TKG is aware of the customized plan.  Then we setup some specific environment variables that will be used in the plan: OIDC_ISSUER_URL, OIDC_USERNAME_CLAIM, OIDC_GROUPS_CLAIM, DEX_CA.  The oidc configuration
requires these.  

Then we ask the management cluster to create the new workload cluster and once complete set the default storage class based upon the iaas.

>Special Note for AWS Deployments: The default behavior is for each cluster (management and workload clusters) to be provisioned in their own VPC.  However, in order to conserve VPC's, we will deploy the workload clusters in the VPC and subnets as the management cluster.  This process is described in the [TKG Docs](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.1/vmware-tanzu-kubernetes-grid-11/GUID-tanzu-k8s-clusters-create.html#aws-vpc) and done automatically via the script below.

All of the steps above can be accomplished by running the following script:

```bash
./scripts/deploy-workload-cluster.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  $(yq r $PARAMS_YAML shared-services-cluster.worker-replicas)
```

>Note: Wait until your cluster has been created. It may take 12 minutes.

>Note: Once cluster is created your kubeconfig will already have the new context as the active one with the necessary credentials.

## Go to Next Step

[Attach Shared Services Cluster to TMC](02_attach_tmc_ssc.md)