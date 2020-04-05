# Install elastic search and kibana

> Note: Update the kibana ingress in `clusters/mgmt/elastic-search-kibana/04-kibana.yaml` to refer to your base domain.  It currently has mine.

```bash
kubectl apply -f clusters/mgmt/elastic-search-kibana/01-namespace.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/02-statefulset.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/03-service.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/04-kibana.yaml
```

Get the load balancer external IP for the elasticsearch service

```bash
kubectl get svc elasticsearch -n tanzu-system-logging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** elasticsearch entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```

## Validation Step

Ensure all pods are in running state.

```bash
kubectl get pods -n tanzu-system-logging
```

Get an response back from elasticsearch rest interface

```bash
curl -v http://elasticsearch.mgmt.tkg-aws-lab.winterfell.live:9200
```