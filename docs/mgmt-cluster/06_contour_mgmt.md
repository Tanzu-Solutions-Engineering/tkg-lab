# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:
```bash
./scripts/deploy-metallb.sh 192.168.14.200 192.168.14.220
```

## Deploy Contour
Locate the folder where you unbundled the TGK extensions (e.g: `tkg-extensions`)

Deploy cert-manager
```bash
kubectl apply -f tkg-extensions/cert-manager/
```

Wait a couple of minutes ... And apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.
```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```

## Set environment variables

The scripts update Google Cloud DNS depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for base domain
export BASE_DOMAIN=winterfell.live
# the Lab name to be used as subdomain
export LAB_NAME=tkg-aws-lab
```

## Setup DNS for Contour Ingress

Get the load balancer external IP for the envoy service and update Google Cloud DNS

```bash
./scripts/update-dns-records.sh "*.mgmt"
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
./scripts/generate-contour-yaml.sh mgmt
kubectl create secret generic acme-account-key \
   --from-file=tls.key=keys/acme-account-private-key.pem \
   -n tanzu-system-ingress
kubectl apply -f clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
```
