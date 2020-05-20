# Install fluent bit

## Set configuration parameters

The scripts to prepare the YAML to deploy fluent-bit depend on a parameters to be set.  Ensure the following are set in `params.yaml':

```yaml
shared-services-cluster.elasticsearch-fqdn: elasticsearch.dorn.tkg-aws-e2-lab.winterfell.live
shared-services-cluster.kibana-fqdn: logs.dorn.tkg-aws-e2-lab.winterfell.live
```

## Prepare Manifests and Deploy Fluent Bit

Prepare the YAML manifests for the related fluent-bit K8S objects.  Manifest will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/fluent-bit/` in case you want to inspect.

```bash
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r params.yaml shared-services-cluster.name)
```

## Validation Step

Ensure that fluent bit pods are running

```bash
kubectl get pods -n tanzu-system-logging
```

## Go to Next Step

[Install Tanzu Observability](docs/shared-services-cluster/08_to_wlc.md)
