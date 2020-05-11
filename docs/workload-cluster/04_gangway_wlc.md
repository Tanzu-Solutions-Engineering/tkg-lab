# Configure Gangway on Management Server

## Set environment variables

The scripts to prepare the YAML to deploy gangway depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for dex service
export DEX_CN=dex.mgmt.tkg-aws-lab.winterfell.live
# the DNS CN that will ultimately map to the ganway service on your first workload cluster
export GANGWAY_CN=gangway.wlc-1.tkg-aws-lab.winterfell.live
# the cluster name
export CLUSTER_NAME=wlc-1
```

## Prepare Manifests

Prepare the YAML manifests for the related gangway K8S objects.  Manifest will be output into `clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/` in case you want to inspect.

```bash
./scripts/generate-gangway-yaml.sh
```

## Deploy Gangway

```bash
kubectl apply -f tkg-extensions/authentication/gangway/aws/01-namespace.yaml
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02-service.yaml
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/02b-ingress.yaml
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/03-config.yaml
# Below is FOO_SECRET intentionally hard coded
kubectl create secret generic gangway \
   --from-literal=sessionKey=$(openssl rand -base64 32) \
   --from-literal=clientSecret=FOO_SECRET \
   -n tanzu-system-auth
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/authentication/gangway/aws/generated/05-certs.yaml
watch kubectl get certificate -n tanzu-system-auth
# Wait for above certificate to be ready.  It took me about 2m20s
kubectl create cm dex-ca -n tanzu-system-auth --from-file=dex-ca.crt=keys/letsencrypt-ca.pem
kubectl apply -f tkg-extensions/authentication/gangway/aws/06-deployment.yaml
```

## Validation Step

Check to see gangway pod is ready

```bash
kubectl get po -n tanzu-system-auth
```
