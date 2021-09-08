# Add Prometheus and Grafana to Management Cluster

## Overview

Tanzu offers essential cluster monitoring with Prometheus and Grafana through TKG packages.  When deployed to a cluster, you have metrics collection and storage, alerting, and dashboards.

>Note: This is an in-cluster service.  Using this approach, you would have to deploy Prometheus and Grafana to each cluster with individual storage and dashboards for each cluster.  Alternatively, Tanzu Observability provides multi-cluster observability and is part of the Tanzu Advanced offering.

In this lab we will be adding monitoring to the management cluster.

## Set configuration parameters

The scripts to prepare and execute the YAML to deploy prometheus and grafana depend on a parameters to be set.  Ensure the following are set in `params.yaml`:

```yaml
# Leave prometheus-fqdn blank if you choose not to expose it, there is no auth
management-cluster.prometheus-fqdn: prometheus.dragonstone.tkg-vsphere-lab.winterfell.live
# Grafana has auth
management-cluster.grafana-fqdn: grafana.dragonstone.tkg-vsphere-lab.winterfell.live
grafana.admin-password: REDACTED
```

## Prepare Manifests and Deploy Prometheus

Prepare the YAML manifests for the related prometheus k8s objects.  Manifests will be output into `generated/$CLUSTER_NAME/monitoring/` in case you want to inspect.

```bash
./scripts/generate-and-apply-prometheus-yaml.sh \
  $(yq e .management-cluster.name $PARAMS_YAML) \
  $(yq e .management-cluster.prometheus-fqdn $PARAMS_YAML)
```

## Prometheus Validation Step

1. (Using Incognito Window) Access prometheus at the configured `management-cluster.prometheus-fqdn` using `https://`
2. Enter `container_memory_working_set_bytes` into search box
3. Choose `Graph` for output
4. Click `Execute` button
5. View results

```bash
open https://$(yq e .management-cluster.prometheus-fqdn $PARAMS_YAML)
```

## Prepare Manifests and Deploy Grafana

Prepare the YAML manifests for the related grafana k8s objects.  Manifests will be output into `generated/$CLUSTER_NAME/monitoring/` in case you want to inspect.

```bash
./scripts/generate-and-apply-grafana-yaml.sh \
  $(yq e .management-cluster.name $PARAMS_YAML) \
  $(yq e .management-cluster.grafana-fqdn $PARAMS_YAML)
```

## Grafana Validation Step

1. (Using Incognito Window) Access grafana at the configured `management-cluster.grafana-fqdn` using `https://`
2. Login with username `admin` and the password you specified as `grafana.admin-password`
3. Now we will import a dashboard.  Choose `+` from left menu, then `Import`
4. Enter `13382` into the Import via grafana.com box, and choose `Load`
5. Choose `Prometheus` from the `Prometheus` dropdown menu, and then click `Import`
6. View the dashboard!

```bash
open https://$(yq e .management-cluster.grafana-fqdn $PARAMS_YAML)
```

## Go to Next Step

[Create new Shared Services Cluster](../shared-services-cluster/01_install_tkg_ssc.md)
