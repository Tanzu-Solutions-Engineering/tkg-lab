# Install FluentBit on Shared Services Cluster

## Set configuration parameters

The scripts to prepare the YAML to deploy fluent-bit depend on a parameters to be set.  Ensure the following are set in `params.yaml':

```yaml
shared-services-cluster.elasticsearch-fqdn: elasticsearch.dorn.tkg-aws-e2-lab.winterfell.live
shared-services-cluster.kibana-fqdn: logs.dorn.tkg-aws-e2-lab.winterfell.live
```

## Prepare Manifests and Deploy Fluent Bit

Prepare the YAML manifests for the related fluent-bit K8S objects.  Manifest will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/fluent-bit/` in case you want to inspect.

```bash
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Validation Step

Ensure that fluent bit pods are running.

```bash
kubectl get pods -n tanzu-system-logging
```

## Test Log Access

1. Access kibana. This leverages the wildcard DNS entry on the convoy ingress. Your base domain will be different than mine.

```bash
open http://$(yq e .shared-services-cluster.kibana-fqdn $PARAMS_YAML)
```

2. You should see the kibana welcome screen.

3. Click the Discover icon at the top of the left menu bar.

4. You will see widget to create an index pattern. Enter `logstash-*` and click next step.

5. Select @timestamp for the Time filter field name. and then click Create index pattern.

6. Now click the Discover icon at the top of the left menu bar. You can start searching for logs.

## Go to Next Step

[Add Prometheus and Grafana to Shared Services Cluster](08_monitoring_ssc.md)
