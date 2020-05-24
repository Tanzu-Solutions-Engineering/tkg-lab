# Configure Gangway on Shared Services Cluster

## Set configuration parameters

The scripts to prepare the YAML to deploy gangway depend on a parameters to be set.  Ensure the following are set in `params.yaml':

```yaml
# the DNS CN to be used for dex service
management-cluster.dex-fqdn: dex.mgmt.tkg-aws-lab.winterfell.live
# the DNS CN that will ultimately map to the ganway service on your first workload cluster
shared-services-cluster.gangway-fqdn: gangway.wlc-1.tkg-aws-lab.winterfell.live
```

## Prepare Manifests and Deploy Gangway

Prepare the YAML manifests for the related gangway K8S objects.  Manifests will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/gangway/` in case you want to inspect.

```bash
./scripts/generate-and-apply-gangway-yaml.sh \
   $(yq r params.yaml shared-services-cluster.name) \
   $(yq r params.yaml shared-services-cluster.gangway-fqdn)
```

This script will check at the end that the Gangway certificate is valid, which depends on the Let's Encrypt / Acme challenge to be resolved, that can take a couple of minutes.

## Final validation Step

Check to see gangway pod is ready

```bash
kubectl get po -n tanzu-system-auth
```

## Inject Gangway as a client for Dex

```bash
./scripts/inject-dex-client.sh \
   $(yq r params.yaml management-cluster.name) \
   $(yq r params.yaml shared-services-cluster.name) \
   $(yq r params.yaml shared-services-cluster.gangway-fqdn)
```

## Validation Step

1. (Using Incognito Window) Login to the workload cluster at the configured `shared-services-cluster.gangway-fqdn` using `https://`
2. Click Sign In
3. Log into okta as alana user
4. Give a secret password
5. Download kubeconfig
6. Attempt to access the cluster with the new config

```bash
KUBECONFIG=~/Downloads/kubeconf.txt kubectl get pods -A
```

## Go to Next Step

[Install ElasticSearch and Kibana](06_ek_ssc.md)
