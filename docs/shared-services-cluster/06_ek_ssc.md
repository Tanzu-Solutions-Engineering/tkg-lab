# Install elastic search and kibana

## Set configuration parameters

The scripts to prepare the YAML to deploy elasticsearch and kibana depend on a parameters to be set.  Ensure the following are set in `params.yaml':

```yaml
# the DNS CN to be used for elasticsearch service
shared-services-cluster.elasticsearch-fqdn: elasticsearch.dorn.tkg-aws-e2-lab.winterfell.live
# the DNS CN to be used for kibana service
shared-services-cluster.kibana-fqdn: logs.dorn.tkg-aws-e2-lab.winterfell.live
```

## Prepare Manifests and Deploy Elasticsearch and Kibana

Prepare the YAML manifests for the related elasticsearch and kibana K8S objects.  Manifests will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/elasticsearch-kibana/` in case you want to inspect.

```bash
./scripts/generate-and-apply-elasticsearch-kibana-yaml.sh
```

## Validation Step

Get an response back from elasticsearch rest interface

```bash
curl -v http://$(yq r $PARAMS_YAML shared-services-cluster.elasticsearch-fqdn)
```

## Go to Next Step

[Install FluentBit](07_fluentbit_ssc.md)
