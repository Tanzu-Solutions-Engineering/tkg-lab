# Install Contour on Shared Services Cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:
```bash
./scripts/deploy-metallb.sh 192.168.14.221 192.168.14.240
```

## Deploy Cert Manager

Our solution leverages cert manager to generate valid ssl certs.  Use this script to deploy cert manager into the cluster using TKG Extensions.

```bash
./scripts/deploy-cert-manager.sh
```

## Deploy Contour


Apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.  Use the script to update the contour configmap to enable `leaderelection` and apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq r params.yaml shared-services-cluster.name)
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
The scripts update Google Cloud DNS depend on a few environmental variables to b
```bash
# the DNS CN to be used for base domain
export BASE_DOMAIN=winterfell.live
# the Lab name to be used as subdomain
export LAB_NAME=tkg-aws-lab
```

## Setup DNS for Contour Ingress (AWS Only)

Get the load balancer external IP for the envoy service and update AWS Route 53.  Execute the script below to do it automatically.

```bash
./scripts/update-dns-records-aws.sh $(yq r params.yaml shared-services-cluster.ingress-fqdn)
```

## Setup DNS for Contour Ingress (vSphere and/or GCP Cloud DNS)

Get the load balancer external IP for the envoy service and update Google Cloud DNS

```bash
./scripts/update-dns-records.sh "*.wlc-1"
```

## Set environment variables (vSphere and/or GCP Cloud DNS)

The scripts to prepare the YAML to deploy the contour cluster issuer depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the email to be used with Lets Encrypt / ACME
export LETS_ENCRYPT_ACME_EMAIL=dpfeffer@vmware.com
```

## Create GCP Cloud DNS Secret (vSphere and GCP Cloud DNS)
Create a secret with the same json file we created during the mgmt lab:

```bash
kubectl create secret generic certbot-gcp-service-account \
        --from-file=keys/certbot-gcp-service-account.json \
        -n cert-manager
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/wlc-1/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect.
Select `http` or `dns` challenge for ACME Issuer. `dns` challenge is recommended for vSphere or non-internet facing AWS environments
```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r params.yaml shared-services-cluster.name) http
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Gangway](docs/workload-cluster/05_gangway_ssc.md)