# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:

```bash
./scripts/deploy-metallb.sh \
        $(yq r params.yaml management-cluster.name) \
        $(yq r params.yaml management-cluster.metallb-start-ip) \
        $(yq r params.yaml management-cluster.metallb-end-ip)
```

## Deploy Contour

Apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.  Use the script to update the contour configmap to enable `leaderelection` and apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq r params.yaml management-cluster.name)
```

## Verify Contour

Once it is deployed, wait until you can see the Load Balancer up.  

```bash
kubectl get svc -n tanzu-system-ingress
```

## Check out Cloud Load Balancer (AWS Only)

The EXTERNAL IP for AWS will be set to the name of the newly configured AWS Elastic Load Balancer, which will also be visible in the AWS UI and CLI:

```bash
kubectl get svc -n tanzu-system-ingress
aws elb describe-load-balancers
```

## Setup DNS for Contour Ingress

Need to get the load balancer external IP for the envoy service and update AWS Route 53.  Execute the script below to do it automatically.

```bash
./scripts/update-dns-records-route53.sh $(yq r params.yaml management-cluster.ingress-fqdn)
```

## Set environment variables (vSphere and/or GCP Cloud DNS)

The scripts to prepare the YAML to deploy the contour cluster issuer depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the email to be used with Lets Encrypt / ACME
export LETS_ENCRYPT_ACME_EMAIL=dpfeffer@vmware.com
```

## Setup GCP Cloud DNS Service Account (vSphere and GCP Cloud DNS)

When using GCP Cloud DNS and vSphere or non-internet facing AWS environments, you'll need to use a `dns` challenge and so allow `cert-manager` to configure your Cloud DNS zone to solve the challenge.

Create a service account in GCP following these [instructions](https://certbot-dns-google.readthedocs.io/en/stable/) and then store the service account json file at *keys/certbot-gcp-service-account.json*

Then create a secret with that json file:
```bash
kubectl create secret generic certbot-gcp-service-account \
        --from-file=keys/certbot-gcp-service-account.json \
        -n cert-manager
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect.
Select `http` or `dns` challenge for ACME Issuer. `dns` challenge is recommended for vSphere or non-internet facing AWS environments
```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r params.yaml management-cluster.name) http
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Dex](07_dex_mgmt.md)