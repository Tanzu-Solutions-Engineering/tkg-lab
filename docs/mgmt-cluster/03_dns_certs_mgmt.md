# Overview

We can use any DNS provider that is publicly available.  This is required because any certificate that is generated will use cert-manager and Let's Encrypt, with an HTTP01 or a DNS01 challenge, depending on the environment's connectivity. To learn more about the different challenges go [here](https://letsencrypt.org/docs/challenge-types/).

Throughout these labs we will follow the steps to set this up with AWS Route 53, but a similar approach can be followed with Google Cloud DNS and other publicly available DNS providers. We also follow a command line / script driven approach but all the AWS Route 53 configuration steps can be done via browser.

If you decide to use Google Cloud DNS, please check [these Google Cloud DNS instructions](/docs/misc/google_cloud_dns.md) to understand the different steps you have to follow, and avoid the specific Route53 steps throughout the labs.


# Pre-requisites for Route 53

We need to have the CLI set up for proper access to perform these actions.  These commands should return either no zones or a list of existing zones, which will prove access to perform the commands we need to run as part of the lab.  If you cannot access the DNS zones properly, you can create the zone and associated entries at each step using the browser.

Using a valid access key, run:
```bash
aws configure
aws route53 list-hosted-zones
```


# Route 53 DNS Zone

This will require an AWS Route53 Hosted Zone.  Later we will add record sets as necessary, but we cannot do this until the Contour Load Balancer and AWS ELB get created.  For now, run the following script that will create a new hosted zone and store its ID in the params.yaml file.  It leverages the following configuration you have already set: `subdomain`.

```bash
./scripts/create-hosted-zone.sh
```

# Update DNS to Leverage Hosted Zones

You will need the NS records from the hosted zone within your domain registration. This can be easily retrieved from your AWS Route 53 console. Ensure they are included where ever you have your domain registered.

# Retrieve the CA Cert from Let's Encrypt for use later

It's not required to set up a Let's Encrypt account in advance. Only needed to be able to solve the (http01 or dns01) challenges by proving that the requester of the certificate owns the domain.  However, if we use Let's Encrypt, we will need the CA cert for later steps. Run the following script to retrieve the CA cert and put it in the `keys` directory.

```bash
./scripts/retrieve-lets-encrypt-ca-cert.sh
```

## Go to Next Step

[Configure Okta](04_okta_mgmt.md)
