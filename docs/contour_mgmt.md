# Install Contour on management cluster

## Deploy Contour

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```

## Setup DNS for Contour Ingress

Get the load balancer external IP for the envoy service

```bash
kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** wildcard management `*.mgmt` entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
./scripts/update-dns-records.sh
```

## Set environment variables

The scripts to prepare the YAML to deploy the contour cluster issuer depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the email registered with ACME
export LETS_ENCRYPT_ACME_EMAIL=dpfeffer@pivotal.io
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/contour/generated/` in case you want to inspect.

```bash
./scripts/generate-contour-yaml-mgmt.sh
kubectl create secret generic acme-account-key \
   --from-file=tls.key=keys/acme-account-private-key.pem \
   -n tanzu-system-ingress
kubectl apply -f clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
```
