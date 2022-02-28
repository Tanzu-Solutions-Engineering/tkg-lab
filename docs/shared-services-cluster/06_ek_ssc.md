# Install Elasticsearch and Kibana

We will deploy Elasticsearch and Kibana as a target for logs.  This is [one of several potential targets for TKG to send logs](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-packages-logging-fluentbit.html).

This is a minimalist and POC quality deployment of Elasticsearh and Kibana.  This is not a component of Tanzu.  This deployment is just for the purpose of demonstration purpose.  See notes below if you face issues with the Elasticsearch deployment.

## Set configuration parameters

The scripts to prepare the YAML to deploy elasticsearch and kibana depend on a parameters to be set.  Ensure the following are set in `params.yaml`:

```yaml
# the DNS CN to be used for elasticsearch service
shared-services-cluster.elasticsearch-fqdn: elasticsearch.dorn.tkg-aws-e2-lab.winterfell.live
# the DNS CN to be used for kibana service
shared-services-cluster.kibana-fqdn: logs.dorn.tkg-aws-e2-lab.winterfell.live
```

## Prepare Manifests and Deploy Elasticsearch and Kibana

Elasticsearch and kibana images are pulled from Docker Hub.  Ensure your credentials are in the `params.yaml` file in order to avoid rate limit errors.

```yaml
dockerhub:
  username: REDACTED # Your dockerhub username
  password: REDACTED # Your dockerhub password
  email: REDACTED # Your dockerhub email
```

Prepare the YAML manifests for the related elasticsearch and kibana K8S objects.  Manifests will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/elasticsearch-kibana/` in case you want to inspect.

```bash
./scripts/generate-and-apply-elasticsearch-kibana-yaml.sh
```

## Validation Step

Get an response back from elasticsearch rest interface

```bash
curl -v http://$(yq e .shared-services-cluster.elasticsearch-fqdn $PARAMS_YAML)
```

## Go to Next Step

[Install FluentBit on Shared Services Cluster](07_fluentbit_ssc.md)

## Troubleshooting Steps

Your probably don't need these now, but may if your lab environment is running for any extended period of time.

Some notes about this "POC/Quality" Elasticsearch / Kibana deployment.
- As Elasticsearch is used to demonstrate Tanzu capability, the is no effort being placed into deploying elasticsearch with best practices.  
- There is only one elasticsearch node created.  
- You will notice that the indexes are in yellow status and will not become green.  This is because the replica shared can not run on the same node as the primary shard.
- A curator cronjob is created to delete indexes older than 1 day. This is to ensure we don't fill up our peristent volume disk.

Here are some troubleshooting commands.  Update FQDN below with your configuration

```bash
export ELASTICSEARCH_CN=$(yq e .shared-services-cluster.elasticsearch-fqdn $PARAMS_YAML)

# Get General information from elasticsearch
curl "http://$ELASTICSEARCH_CN"

# Get Size/Status of Indexes. Notice that logstash-YYYY.MM.DD is in yellow (typically a shard in the index is not active)
curl "http://$ELASTICSEARCH_CN/_cluster/aat/indices"

# Get status of the shards.  Notice the replica is unalocated.
curl "http://$ELASTICSEARCH_CN/_cat/shards?v&h=n,index,shard,prirep,state,sto,sc,unassigned.reason,unassigned.details&s=sto,index"

# Since the index name changes based upon date, let's use this long command to retrieve the unassigned index name, to be used in ex command
export INDEX_NAME=`curl "http://$ELASTICSEARCH_CN/_cat/shards?v&h=n,index,shard,prirep,state,sto,sc,unassigned.reason,unassigned.details&s=sto,index" | grep UNASSIGNED | awk '{print $(1)}'`

# Get details of the allocation status for the unallocated shard.  See that it is not allocated because we only have one node in our cluster and replica can not be placed on same node as the primary
curl -X GET "http://$ELASTICSEARCH_CN/_cluster/allocation/explain?pretty" -H 'Content-Type: application/json' -d"{\"index\": \"$INDEX_NAME\",\"shard\": 0,\"primary\": false }"
```
