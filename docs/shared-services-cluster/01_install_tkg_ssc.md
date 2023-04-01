# Create new Shared Services Cluster

Here we will deploy a new workload cluster for use as the Shared Services cluster.  The shared services cluster in our opinionated deployment is a special purpose workload cluster where common services are deployed.  All workload clusters will have similar steps for initial setup.

Here we are pulling the following values from the `params.yaml` file.  See examples

```yaml
# the DNS CN to be used for Pinniped service
management-cluster.pinniped-fqdn: pinniped.mgmt.tkg-aws-lab.winterfell.live
shared-services-cluster.name: dorn
shared-services-cluster.worker-replicas: 2
iaas: aws
```

We need to setup a cluster configuration file for our new workload cluster.  

Then we ask the management cluster to create the new workload cluster.

>Special Note for AWS Deployments: We will deploy the workload clusters in the same VPC and subnets as the management cluster. This lab only generates a VPC and subnets once prior to the deployment of the MC.

All of the steps above can be accomplished by running the following script:

```bash
./scripts/deploy-workload-cluster.sh \
  $(yq e .shared-services-cluster.name $PARAMS_YAML) \
  $(yq e .shared-services-cluster.worker-replicas $PARAMS_YAML) \
  $(yq e .shared-services-cluster.controlplane-endpoint $PARAMS_YAML) \
  $(yq e '.shared-services-cluster.kubernetes-version // null' $PARAMS_YAML)
```

>Note: The kubernetes-version parameter is optional for the script and if you don't have it in your configuration, then it will default to the default version of the tanzu cli.  You can get a list of valid options to supply in the kubernetes-version parameter by issuing the `tanzu kubernetes-release get` and choose the appropriate value from the name column.

>Note: Wait until your cluster has been created. It may take 12 minutes.

>Note: Once cluster is created your kubeconfig will already have the new context as the active one with the necessary credentials.

>Note: You can view the cluster-config.yaml file generated for this cluster at `generated/$CLUSTER_NAME/cluster-config.yaml`.

## Go to Next Step

[Attach Shared Services Cluster to TMC](02_attach_tmc_ssc.md)
