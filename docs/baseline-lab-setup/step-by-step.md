# Step by Step Setup

The following labs guide you through the steps to create the three clusters considered the baseline setup.

>Note: The labs depend on a master `params.yaml` file that is used for environment specific configuration data.  A sample `REDACTED-params.yaml` file is included at the root of this repo, named REDACTED-params.yaml.  It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments.  `local-config/` is included in the `.gitignore` so your version won't be included in an any future commits you have to the repo.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file.  If you followed the recommendation, the value would be `local-config/params.yaml`, however you may choose otherwise.  This may be the case if you are using multiple `params.yaml` files in the case of AWS and vSphere deployments.

```bash
# Update the the path from the default if you have a different params.yaml file name or location.
export PARAMS_YAML=local-config/params.yaml
```

## Management Cluster
### 1. [Install Management Cluster](../mgmt-cluster/01_install_tkg_mgmt.md)
### 2. [Attach Management Cluster to TMC](../mgmt-cluster/02_attach_tmc_mgmt.md)
### 3. [Configure DNS and Prep Certificate Signing](../mgmt-cluster/03_dns_certs_mgmt.md)
### 4. [Configure Okta](../mgmt-cluster/04_okta_mgmt.md)
### 5. [Install Contour Ingress Controller](../mgmt-cluster/06_contour_mgmt.md)
### 6. [Update Pinniped Configuration](../mgmt-cluster/07_update_pinniped_config_mgmt.md)
### 7. [Add monitoring](../mgmt-cluster/08_monitoring_mgmt.md)

## Setup Shared Services Cluster
### 1. [Create new Shared Services Cluster](../shared-services-cluster/01_install_tkg_ssc.md)
### 2. [Attach Shared Services Cluster to TMC](../shared-services-cluster/02_attach_tmc_ssc.md)
### 3. [Set policy on Shared Services Cluster and Namespace](../shared-services-cluster/03_policy_ssc.md)
### 4. [Install Contour Ingress Controller](../shared-services-cluster/04_contour_ssc.md)
### 5. [Install ElasticSearch and Kibana](../shared-services-cluster/06_ek_ssc.md)
### 6. [Install FluentBit](../shared-services-cluster/07_fluentbit_ssc.md)
### 7. [Add monitoring to cluster](../shared-services-cluster/08_monitoring_ssc.md)
### 8. [Deploy Minio to Shared Services Cluster](../shared-services-cluster/08_5_minio_ssc.md)
### 8. [Enable Data Protection and Setup Nightly Backup](../shared-services-cluster/09_velero_ssc.md)
### 9. [Install Harbor](../shared-services-cluster/10_harbor.md)

## Finalize Management Cluster
### 1. [Install FluentBit](../mgmt-cluster/09_fluentbit_mgmt.md)
### 2. [Enable Data Protection and Setup Nightly Backup](../mgmt-cluster/10_velero_mgmt.md)

## Setup Workload Cluster
### 1. [Create new Workload Cluster](../workload-cluster/01_install_tkg_and_components_wlc.md)

At this point you have the basis for the lab exercises!
