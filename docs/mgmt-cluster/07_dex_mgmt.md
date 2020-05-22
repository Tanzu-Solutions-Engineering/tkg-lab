# Configure Dex on Management Server

## Set configuration parameters

The scripts to prepare the YAML to deploy dex depend on a parameters to be set.  Ensure the following are set in `params.yaml`:

```yaml
# the DNS CN to be used for dex service
management-cluster.dex-fqdn: dex.mgmt.tkg-aws-lab.winterfell.live
# the default auth server url from Okta
okta.auth-server-fqdn: dev-866321145.okta.com
# the client id and secret from the app you created in Okta for Dex
okta.dex-app-client-id: 123adsfsadf3234r
okta.dex-app-client-secret: 123adsfsadf3234r
```

## Prepare Manifests and Deploy Dex

Prepare the YAML manifests for the related dex K8S objects.  Manifests will be output into `generated/$MANAGMEMENT_CLUSTER_NAME/dex/` in case you want to inspect.

We can currently use the base aws yaml for any environment.

```bash
./scripts/generate-and-apply-dex-yaml.sh
```

## Validation Step

Check to see dex pod is ready

```bash
kubectl get po -n tanzu-system-auth
```

## Go to Next Step

[Install Tanzu Observability](08_to_mgmt.md)