# Configure DNS and Prep Certificate Signing

We can use any DNS provider that is publicly available.  This is required because any certificate that is generated will use cert-manager and Let's Encrypt, with an HTTP01 or a DNS01 challenge, depending on the environment's connectivity. To learn more about the different challenges go [here](https://letsencrypt.org/docs/challenge-types/).

Throughout these labs we will follow the steps to set this up with AWS Route 53, but a similar approach can be followed with Google Cloud DNS and other publicly available DNS providers. We also follow a command line / script driven approach but all the AWS Route 53 configuration steps can be done via browser.

If you decide to use Google Cloud DNS, please check [these Google Cloud DNS instructions](/docs/misc/goog_cloud_dns.md) to understand the different steps you have to follow, and avoid the specific Route53 steps throughout the labs.


# Pre-requisites for Route 53

We need to have the aws CLI set up for proper access to perform these actions.  These commands should return either no zones or a list of existing zones, which will prove access to perform the commands we need to run as part of the lab.  If you cannot access the DNS zones properly, you can create the zone and associated entries at each step using the browser.

Using a valid access key, run:
```bash
aws configure
aws route53 list-hosted-zones
```

# Pre-requisites for Cloud DNS

Google Cloud DNS is not the default approach, and to enable it instead of Route 53 you need to set this property on the `params.yml`:
```
dns:
  provider: gcloud-dns
```

We need to have the gcloud CLI set up for proper access (account, project, region, zone) to perform these actions.  These commands should return either no zones or a list of existing zones, which will prove access to perform the commands we need to run as part of the lab.  If you cannot access the DNS zones properly, you can create the zone and associated entries at each step using the browser.

Run:
```bash
gcloud init
gcloud dns managed-zones list
```

# Prepare DNS Zone

This will make sure there is an AWS Route53 Hosted Zone (default), or a Google Cloud DNS managed-zone if chose that approach.  Later we will add record sets as necessary, but we cannot do this until the Contour Load Balancer gets created.  For now, run the following script that will create a new zone. It will also store its ID in the params.yaml file for Route 53.  It leverages the following configuration you have already set: `subdomain`, `environment-name`.

```bash
./scripts/create-dns-zone.sh
```

# Update DNS to Leverage Hosted Zones

You will need the NS records from the hosted zone within your domain registration. This can be easily retrieved from your AWS Route 53 console, or Google Cloud DNS console if you chose that approach. Ensure they are included where ever you have your domain registered.

# Retrieve the CA Cert from Let's Encrypt for use later

It's not required to set up a Let's Encrypt account in advance. Only needed to be able to solve the (http01 or dns01) challenges by proving that the requester of the certificate owns the domain.  However, if we use Let's Encrypt, we will need the CA cert for later steps. Run the following script to retrieve the CA cert and put it in the `keys` directory.

```bash
./scripts/retrieve-lets-encrypt-ca-cert.sh
```

## Go to Next Step

[Configure Okta](04_okta_mgmt.md)
