# Install elastic search and kibana

## Set environment variables

The scripts to prepare the YAML to deploy elasticsearch and kibana depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for elasticsearch service
export ELASTICSEARCH_CN=elasticsearch.mgmt.tkg-aws-lab.winterfell.live
# the DNS CN to be used for kibana service
export KIBANA_CN=logs.mgmt.tkg-aws-lab.winterfell.live
```

## Prepare Manifests

Prepare the YAML manifests for the related elasticsearch and kibana K8S objects.  Manifest will be output into `clusters/mgmt/elasticsearch-kibana` in case you want to inspect.

```bash
./scripts/generate-elasticsearch-kibana-yaml.sh
```

## Deploy Elasticsearch and Kibana

```bash
kubectl apply -f clusters/mgmt/elasticsearch-kibana/
kubectl apply -f clusters/mgmt/elasticsearch-kibana/generated
```

## Validation Step

Ensure all pods are in running state.

```bash
kubectl get pods -n tanzu-system-logging
```

Get an response back from elasticsearch rest interface

```bash
curl -v http://elasticsearch.mgmt.tkg-aws-lab.winterfell.live
```