# Install FluentBit on Management Cluster

**You must complete the [Install ElasticSearch and Kibana](../shared-services-cluster/06_ek_scc.md) lab prior to this lab.**

## Prepare Manifests and Deploy Fluent Bit

Prepare the YAML manifests for the related fluent-bit K8S objects.  Manifest will be output into `generated/$CLUSTER_NAME/fluent-bit/` in case you want to inspect.

```bash
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq e .management-cluster.name $PARAMS_YAML)
```

## Validation Step

Ensure that fluent bit pods are running

```bash
kubectl get pods -n tanzu-system-logging
```

Access kibana.  This leverages the wildcard DNS entry on the convoy ingress.  Your base domain will be different than mine.

```bash
open http://$(yq e .shared-services-cluster.kibana-fqdn $PARAMS_YAML)
```

You should see the kibana welcome screen.  

We assume you have already configured your kibana index during the configuration of [FluentBit for Shared Services Cluster](../shared-services-cluster/07_fluentbit_ssc.md).

Click the Discover icon at the top of the left menu bar.  You can start searching for management cluster logs.

## Go to Next Step

[Install Velero and Setup Nightly Backup on Management Cluster](10_velero_mgmt.md)
