# Configure Dex on Management Server

## Set environment variables

The scripts to prepare the YAML to deploy dex depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for dex service
export DEX_CN=dex.mgmt.tkg-aws-lab.winterfell.live
# the DNS CN that will ultimately map to the ganway service on your first workload cluster
export GANGWAY_CN=gangway.wlc-1.tkg-aws-lab.winterfell.live
# the default auth server url from Okta
export OCTA_AUTH_SERVER_CN=dev-866321145.okta.com
# the client id and secret from the app you created in Okta for Dex
export OCTA_DEX_APP_CLIENT_ID=123adsfsadf3234r
export OCTA_DEX_APP_CLIENT_SECRET=123adsfsadf3234r
# the workload cluster name
export CLUSTER_NAME=wlc-1
```

## Prepare Manifests

Prepare the YAML manifests for the related dex K8S objects.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/` in case you want to inspect.

```bash
./scripts/generate-dex-yaml.sh
```

## Deploy Dex
We can currently use the base aws yaml for any environment.

```bash
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/01-namespace.yaml
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02-service.yaml
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/02b-ingress.yaml
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/03-certs.yaml
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/generated/sensitive/04-cm.yaml
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/05-rbac.yaml
# Same environment variables set previously
kubectl create secret generic oidc \
   --from-literal=clientId=$OCTA_DEX_APP_CLIENT_ID \
   --from-literal=clientSecret=$OCTA_DEX_APP_CLIENT_SECRET \
   -n tanzu-system-auth
# Wait for certificate to be ready that generates the dex-cert-tls secret.  It took me about 2m20s
watch kubectl get certificate -n tanzu-system-auth
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/06-deployment.yaml
```

## Validation Step

Check to see dex pod is ready

```bash
kubectl get po -n tanzu-system-auth
```
