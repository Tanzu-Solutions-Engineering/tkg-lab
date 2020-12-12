# Install fluent bit

**You must complete the [Install ElasticSearch and Kibana](docs/shared-services-cluster/06_ek_scc.md) lab prior to this lab.**

## Prepare Manifests and Deploy Fluent Bit

Prepare the YAML manifests for the related fluent-bit K8S objects.  Manifest will be output into `generated/$CLUSTER_NAME/fluent-bit/` in case you want to inspect.

```bash
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Validation Step

Ensure that fluent bit pods are running

```bash
kubectl get pods -n tanzu-system-logging
```

Access kibana.  This leverages the wildcard DNS entry on the convoy ingress.  Your base domain will be different than mine.

```bash
open http://$(yq r $PARAMS_YAML shared-services-cluster.kibana-fqdn)
```

You should see the kibana welcome screen.  

Click the Discover icon at the top of the left menu bar.

You will see widget to create an index pattern.  Enter `logstash-*` and click `next step`.

Select `@timestamp` for the Time filter field name. and then click `Create index pattern`

Now click the Discover icon at the top of the left menu bar.  You can start searching for logs.

## Go to Next Step

[Enable Data Protection and Setup Nightly Backup](10_velero_mgmt.md)
