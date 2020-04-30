# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:
```bash
./scripts/deploy-metallb.sh 192.168.14.200 192.168.14.220
```

## Deploy Contour

Wait a couple of minutes ... And apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```
## Verify Contour and AWS ELB (AWS Only)

Once it is deployed, wait until you can see the Load Balancer up.  The EXTERNAL IP for AWS will be set to the name of the newly configured AWS Elastic Load Balancer, which will also be visible in the AWS UI and CLI:

```bash
kubectl get svc -n tanzu-system-ingress
aws elb describe-load-balancers
```

## Set environment variables (AWS Only)

The scripts update AWS Route 53 depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for base domain
export BASE_DOMAIN=XXXX  # Example (you own): abcdef.com
export AWS_HOSTED_ZONE=XXXXX  # Example: Z10167121Y8UT67T01XXX
```

## Set environment variables (vSphere and/or GCP Cloud DNS)
@@ -27,14 +27,16 @@ The scripts update Google Cloud DNS depend on a few environmental variables to b
```bash
# the DNS CN to be used for base domain
export BASE_DOMAIN=winterfell.live
# the Lab name to be used as subdomain
export LAB_NAME=tkg-aws-lab
```

## Setup DNS for Contour Ingress (AWS Only)

Get the load balancer external IP for the envoy service and update AWS Route 53

```bash
./scripts/update-dns-records-aws.sh "*.mgmt"
```

## Setup DNS for Contour Ingress (vSphere and/or GCP Cloud DNS)

Get the load balancer external IP for the envoy service and update Google Cloud DNS

```bash
./scripts/update-dns-records.sh *.mgmt
./scripts/update-dns-records.sh "*.mgmt"
```

## Set environment variables

The scripts to prepare the YAML to deploy the contour cluster issuer depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the email to be used with Lets Encrypt / ACME
export LETS_ENCRYPT_ACME_EMAIL=dpfeffer@pivotal.io
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/contour/generated/` in case you want to inspect.

```bash
./scripts/generate-contour-yaml.sh mgmt
kubectl apply -f clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/contour-cluster-issuer.yaml
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True
