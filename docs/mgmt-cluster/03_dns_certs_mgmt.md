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

Before creating the DNS Zone on either DNS Cloud solution, set the BASE_DOMAIN and LAB_SUBDOMAIN into the shell.  These will be used throughout the lab:

```bash
export BASE_DOMAIN=YOUR_BASE_DOMAIN   # Example (must own this): abcdef.com 
export LAB_SUBDOMAIN=tkg-aws-lab.${BASE_DOMAIN}
```
# DNS Zone

For AWS, this will require a Route53 Hosted Zone.  Later we will add record sets as necessary, but we cannot do this until the Copntour Load Balancer and AWS ELB get created.  For now, create a hosted zone and record the ID:

```bash
aws route53 create-hosted-zone --name ${LAB_SUBDOMAIN} --caller-reference "${LAB_SUBDOMAIN}-`date`"
export AWS_HOSTED_ZONE=XXXXXXXXX # From the output, just the ID characters
```

For GCP, this will use GCP Cloud DNS:

```bash
export BASE_DOMAIN=YOUR_BASE_DOMAIN   # Example (must own this): abcdef.com 
gcloud dns managed-zones create ${LAB_SUBDOMAIN} \
  --dns-name ${LAB_SUBDOMAIN} \
  --description "TKG AWS Lab domains"
```
