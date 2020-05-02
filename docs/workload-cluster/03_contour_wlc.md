# Install Contour on management cluster

## Install Cert Manager

```bash
kubectl apply -f tkg-extensions/cert-manager/
# Wait for all pods to be ready
watch kubectl get pods -n cert-manager
```

## Deploy Contour

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```

## Set environment variables

The scripts update Google Cloud DNS depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for base domain
export BASE_DOMAIN=winterfell.live
```

## Setup DNS for Contour Ingress

Get the load balancer external IP for the envoy service and update AWS Route 53

```bash
./scripts/update-dns-records-aws.sh *.wlc-1
```

## Set environment variables

The scripts to prepare the YAML to deploy the contour cluster issuer depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the email registered with ACME
export LETS_ENCRYPT_ACME_EMAIL=dpfeffer@vmware.com
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/wlc-1/contour/generated/` in case you want to inspect.

```bash
./scripts/generate-contour-yaml.sh wlc-1
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True