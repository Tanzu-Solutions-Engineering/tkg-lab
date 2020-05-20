# Overview

We can use any DNS provider that is publicly available.  This is required because any certificate that is generated will use cert-manager and Let's Encrypt, with an HTTP01 challenge.  This works through Kubernetes as follows:

Public Domain Name -> DNS Hosted Zone -> Cloud Load Balancer -> K8s Load Balancer -> Contour -> Ingress (temporary) for Challenge

# Pre-requisites

Depending on the DNS solution to be used, we need to have the CLI set up for proper access to perform these actions.  In both cases, these commands should return either no zones or a list of existing zones, which will prove access to perform the commands we need to run as part of the lab.  If you cannot access the DNS zones properly, you can create the zone and associated entries at each step using the browser.

For AWS, this will mean using a valid access key and running:
```bash
aws configure
aws route53 list-hosted-zones
```

For GCP, the account used must have access to modify GCloud DNS:
```bash
gcloud auth list
gcloud dns managed-zones list
```

# DNS Zone

For AWS, this will require a Route53 Hosted Zone.  Later we will add record sets as necessary, but we cannot do this until the Contour Load Balancer and AWS ELB get created.  For now, run the following script that will create a new hosted zone and store its ID in the params.yaml file.  It leverages the following configuration you have already set: `subdomain`.

```bash
./scripts/create-hosted-zone.sh
```

For GCP, this will use GCP Cloud DNS:

```bash
export BASE_DOMAIN=YOUR_BASE_DOMAIN   # Example (must own this): abcdef.com
gcloud dns managed-zones create ${LAB_SUBDOMAIN} \
  --dns-name ${LAB_SUBDOMAIN} \
  --description "TKG AWS Lab domains"
```

# Update DNS to Leverage Hosted Zones

You will need the NS records from the hosted zone within your domain registration.  Use AWS Route 53 or GCP Cloud DNS to retrieve the NS records and ensure they are included where ever you have your domain registered.

# Retrieve the CA Cert from Let's Encrypt for use later
It's not required to set up a Let's Encrypt account in advance. Only needed to be able to solve the (http01 or dns01) challenges by proving that the requester of the certificate owns the domain.  However, if we use Let's Encrypt, we will need the CA cert for later steps. Run the following script to retrieve the CA cert and put it in the `keys` directory.

```bash
./scripts/retrieve-lets-encrypt-ca-cert.sh
```

## Go to Next Step

[Configure Okta](04_okta_mgmt.md)
