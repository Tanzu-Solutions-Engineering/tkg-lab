# Tanzu Kubernetes Grid - Hands on Lab

This is a `Hands-on-Lab` to deploy **Tanzu Kubernetes Grid** and its extensions in AWS and vSphere. This lab uses helm charts for all extensions. You should be able to create Management cluster, Shared Service Cluster and Workload cluster with all extensions.
For TMC setup, please refer to TKG-LAB documentation to attach all three clusters and apply role bindings. You can use ACME Fitness lab to deploy workload on workload cluster but you just need to make sure that you are using right ingress provided in params.yaml file in helm install directory.

## External DNS.

This lab is also using External DNS. External DNS creates wild card DNS entries for envoy service. External DNS does not support HTTPProxy CRD so for this lab we are using wild card dns entries for Load Balancer service.

## Helm Charts.

Below are the instructions to install extension using helm charts on any TKG cluster considering you already have clusters up and running with all prerequisities.

#### Cert-Manager

```bash
helm upgrade -n cert-manager --create-namespace --install cert-manager ./tkg-extensions-helm-charts/cert-manager-0.1.0.tgz --wait
```

#### Contour

```bash
helm upgrade -n tanzu-system-ingress --create-namespace --install contour ./tkg-extensions-helm-charts/contour-0.1.0.tgz \
--set ingress.host=$DNS --wait
```

#### Dex

```bash
helm upgrade -n tanzu-system-auth --create-namespace --install dex ./tkg-extensions-helm-charts/dex-0.1.0.tgz \
--set svcCluster.gangway=$dns \
--set svcCluster.id=$cluster_name \
--set svcCluster.name=$cluster_name \
--set wlCluster.id=$cluster_name \
--set wlCluster.name=$cluster_name \
--set svcCluster.secret=$secret \
--set wlCluster.secret=$secret \
--set wlCluster.gangway=$dns \
--set oidc.oidcUrl=$oidcurl \
--set oidc.oidcClientId=$oidcClientId \
--set oidc.oidcClientSecret=$oidcClientSecret \
--set ingress.host=$dexhost --wait
```
#### Gangway

```bash
helm upgrade -n tanzu-system-auth --create-namespace --install gangway ./tkg-extensions-helm-charts/gangway-0.1.0.tgz \
--set gangway.secret=$(echo -n $SECRET | base64) \
--set gangway.secretKey=$(openssl rand -base64 32) \
--set cluster.name=$CLUSTER_NAME \
--set cluster.apiServerName=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}") \
--set dex.hostname=$dex_dns \
--set ingress.host=$GANGWAY_INGRESS
```

#### Elastic Search - Kibana

```bash
helm upgrade -n tanzu-system-logging --create-namespace --install elasticsearch-kibana ./tkg-extensions-helm-charts/elasticsearch-kibana-0.1.0.tgz \
--set elasticsearch.host=$elasticsearch_dns \
--set kibana.host=$kibana_dns
```

#### Fluentbit

```bash
helm upgrade -n tanzu-system-logging --create-namespace --install fluent-bit ./tkg-extensions-helm-charts/fluent-bit-0.1.0.tgz \
 --set elasticsearch.host=$elasticsearch_dns \
 --set elasticsearch.port=$elasticsearch_port) \
 --set tkg.clusterName=$CLUSTER_NAME \
 --set tkg.instanceName=$CLUSTER_NAME
 ```

#### Metallb

```bash
helm upgrade -n metallb --create-namespace --install metallb bitnami/metallb -f $METALLB_VALUES_FILE
```

## Steps:

## 0 - Prerequisites

Make sure you have the below CLI's installed on your machine. Please make sure that you are using params.yaml file provided in helmisntall directory. Since TKG-LAb and helminstall using two different params.yaml file but they are going to merged in next iterations.

##### Required CLIs

- kubectl
- tkg
- helm 3 - latest version
- yq

[Follow the instructions here to complete the Prerequisites.](management-cluster-setup/02-create-mgmt-cluster/00-prerequisities.md)


## 1 - Install TKG Management Cluster -

  - [Setup Bootstrap Environment & Creating Management Cluster](management-cluster-setup/02-create-mgmt-cluster/01_install_tkg_mgmt.md)
  - [Configure External DNS and/or Metallb](management-cluster-setup/02-create-mgmt-cluster/02_install_external_dns.md)
  - [Configure Contour](management-cluster-setup/02-create-mgmt-cluster/03_configure_contour.md)
  - [Configure DEX](management-cluster-setup/02-create-mgmt-cluster/04_install_dex.md)


## 2 - Create Shared Service Cluster & Install TKG Extensions

  - [Create a Shared Services Cluster](shared-services-cluster-setup/01_install_tkg_service-cluster.md)
  - [Configure TMC](shared-services-cluster-setup/01a-configure-tmc.md)       
  - [Configure Certificate Manager](shared-services-cluster-setup/02-install-cert-manager.md)
  - [Insall External DNS and/or Metallb](shared-services-cluster-setup/03_install_external_dns.md)
  - [Configure Ingress Controller - Contour](shared-services-cluster-setup/04_configure_contour.md)
  - [Configure Gangway](shared-services-cluster-setup/04_install_gangway.md)
  - [Configure Tanzu Observability](shared-services-cluster-setup/05-install-wavefront.md)
  - [Configure Elastic Search & Kibana](shared-services-cluster-setup/06-install-elasticsearch-kibana.md)
  - [Configure Fluentbit](shared-services-cluster-setup/07-install-fluent-bit.md)

## 3 - Create Workload Cluster, Install required extensions and Deploy a Workload

  - [Create a Workload Cluster](workload-cluster-setup/01_install_tkg_workload.md)
  - [Configure TMC](workload-cluster-setup/01a-configure-tmc.md)       
  - [Configure Certificate Manager](workload-cluster-setup/02-install-cert-manager.md)
  - [Install External DNS and/or Metallb](workload-cluster-setup/03_install_external_dns.md)
  - [Configure Ingress Controller - Contour](workload-cluster-setup/04_configure_contour.md)
  - [Configure Gangway](workload-cluster-setup/05_install_gangway.md)
  - [Configure Fluentbit](workload-cluster-setup/06-install-fluent-bit.md)
  - [Configure Tanzu Observability](workload-cluster-setup/07-install-wavefront.md)
  - Deploy an Application

    Please follow acme fitness lab. You need to make sure that you are using right ingress.

## 4 - Single Click Deploy

 - [Single click deploy](docs/single-deploy.md)

## 5 - Delete Clusters

 - [Tear down env](docs/tear-down.md)

