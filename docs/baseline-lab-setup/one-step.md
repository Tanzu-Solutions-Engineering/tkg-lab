# One Step Foundation Deployment

This lab can be used to deploy all three clusters included in the foundational lab setup.  You will execute a single script that calls all the scripts included in the step-by-step guides.  

>Note: The labs depending on a master `params.yaml` file that is used for environment specific configuration data.  A sample `REDACTED-params.yaml` file is included at the root of this repo, named REDACTED-params.yaml.  It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments.  `local-config/` is included in the `.gitignore` so your version won't be included in an any future commits you have to the repo.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file.  If you followed the recommendation, the value would be `local-config/param.yaml`, however you may choose otherwise.  This may be the case if you are using multiple `params.yaml` files in the case of AWS and vSphere deployments.

```bash
# Update the the path from the default if you have a different params.yaml file name or location.
export PARAMS_YAML=local-config/params.yaml
```

Ensure that your copy of `params.yaml` indicates your IaaS as `aws`, `azure` or `vsphere` appropriately.

## Ensure credentials-velero file is in keys directory

Ensure the credentials-velero file is in keys directory as per [Install Velero and Setup Nightly Backup on Management Cluster](../mgmt-cluster/10_velero_mgmt.md)

## Azure Only - Configure the Azure CLI and Accept the TKG Azure Base Image License

Ensure the `az` CLI is installed and configured. The deploy all script will use `az` to deploy TKG.

To run management cluster VMs on Azure, [accept the license](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-mgmt-clusters-azure.html#accept-the-base-image-license-4) for their base Kubernetes version and machine OS.

```
az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot22dot5-ubuntu-2004
```

## Execute the Deploy All Script

Now you can execute the following script to perform all of those tasks:

```bash
./scripts/deploy-all.sh
```

>Note: This process should take about 30 minutes to complete.

## Tear Down

Execute the following script to tear down your environment.

```bash
./scripts/delete-all.sh
```
