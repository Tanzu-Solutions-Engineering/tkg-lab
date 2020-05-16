# Tanzu Kubernetes Grid - Hands on Lab

This is a `Hands-on-Lab` to deploy **Tanzu Kubernetes Grid** and its extensions in AWS.


## Steps:

## 0 - Prerequisites

Make sure you have the below CLI's installed on your machine.

##### Required CLIs

- kubectl
- tmc
- tkg
- velero
- helm 3
- yq

[Follow the instructions here to complete the Prerequisites.](management-cluster-setup/02-create-mgmt-cluster/00-prerequisities.md)


## 1 - Install TKG Management Cluster -

  - [Setup Bootstrap Environment & Creating Management Cluster](management-cluster-setup/02-create-mgmt-cluster/01_install_tkg_mgmt.md)
  - [Configure Ingress Controller - Contour](management-cluster-setup/02-create-mgmt-cluster/02_configure_contour.md)
  - [Configure DEX](management-cluster-setup/02-create-mgmt-cluster/03_install_dex.md)


## 2 - Create Shared Service Cluster & Install TKG Extensions

  - [Create a Shared Services Cluster](shared-services-cluster-setup/01_install_tkg_service-cluster.md)

  - [Configure TMC](shared-services-cluster-setup/01a-configure-tmc.md)       

  - [Configure Certificate Manager](shared-services-cluster-setup/02-install-cert-manager.md)

  - [Configure Ingress Controller - Contour](shared-services-cluster-setup/03_configure_contour.md)

  - [Configure Gangway](shared-services-cluster-setup/04_install_gangway.md)

  - [Configure Tanzu Observability](shared-services-cluster-setup/05-install-wavefront.md)

  - [Configure Elastic Search & Kibana](shared-services-cluster-setup/06-install-elasticsearch-kibana.md)

  - [Configure Fluentbit](shared-services-cluster-setup/07-install-fluent-bit.md)

  - [Configure Velero for Backup](shared-services-cluster-setup/08-install-velero.md)


## 3 - Create Workload Cluster, Install required extensions and Deploy a Workload

  - [Create a Workload Cluster](workload-cluster-setup/01_install_tkg_workload.md)

  - [Configure TMC](workload-cluster-setup/01a-configure-tmc.md)       

  - [Configure Certificate Manager](workload-cluster-setup/02-install-cert-manager.md)

  - [Configure Ingress Controller - Contour](workload-cluster-setup/03_configure_contour.md)

  - [Configure Gangway](workload-cluster-setup/04_install_gangway.md)

  - [Configure Tanzu Observability](workload-cluster-setup/05-install-wavefront.md)

  *TODO:*

  - Deploy an Application

    Follow the steps in the below github repo to deploy Acme Fitness Application:

    https://github.com/vmwarecloudadvocacy/acme_fitness_demo/tree/master/kubernetes-manifests

  - Validate the Application

  - Attaching Application to `NSX Tanzu Service Mesh`

## [4 - Single click deploy](docs/single-deploy.md)

## [5 - Tear down env](docs/tear-down.md)

## 6 - Troubleshoot Issues - TODO
