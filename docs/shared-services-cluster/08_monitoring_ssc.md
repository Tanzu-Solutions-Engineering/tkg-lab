# Add Prometheus and Grafana to Shared Services Cluster

## Overview

Just as we did for the management cluster in [Install Monitoring](../mgmt-cluster/08_monitoring_mgmt.md) step, we will add cluster monitoring to the shared services cluster.  The explanation is brief and validation steps skipped in order to reduce redundancy.  Refer to the management cluster step for more details.  

## Prepare Manifests and Deploy Prometheus

Prepare the YAML manifests for the related prometheus k8s objects.  Manifests will be output into `generated/$CLUSTER_NAME/monitoring/` in case you want to inspect.

```bash
./scripts/generate-and-apply-prometheus-yaml.sh \
  $(yq e .shared-services-cluster.name $PARAMS_YAML) \
  $(yq e .shared-services-cluster.prometheus-fqdn $PARAMS_YAML)
```

## Prepare Manifests and Deploy Grafana

Prepare the YAML manifests for the related grafana k8s objects.  Manifests will be output into `generated/$CLUSTER_NAME/monitoring/` in case you want to inspect.

```bash
./scripts/generate-and-apply-grafana-yaml.sh \
  $(yq e .shared-services-cluster.name $PARAMS_YAML) \
  $(yq e .shared-services-cluster.grafana-fqdn $PARAMS_YAML)
```

## Go to Next Step

[Enable Data Protection and Setup Nightly Backup on Shared Services Cluster](09_velero_ssc.md)
