# Setup DNS

I chose Google Cloud DNS because it has a supporting Let's Encrypt Certbot Plugin.

```bash
export BASE_DOMAIN=YOUR_BASE_DOMAIN
#export BASE_DOMAIN=winterfell.live
gcloud dns managed-zones create tkg-aws-lab \
  --dns-name tkg-aws-lab.$BASE_DOMAIN. \
  --description "TKG AWS Lab domains"
```

# Setup a Let's Encrypt Account

Install letsencrypt, certbot, and google plugin.  Then register an account.

```bash
brew install letsencrypt
brew install certbot
sudo pip install certbot-dns-google
sudo certbot register
```

Find the private_key that was created when you registered your account.  Mine was in this location, but you will have a separate GUID.

```bash
sudo cat /etc/letsencrypt/accounts/acme-v02.api.letsencrypt.org/directory/656b908c7d8dcf0d776091115fc00563/private_key.json
```

And then go to this [website](https://8gwifi.org/jwkconvertfunctions.jsp) to convert from jwt to pem.  Save the private key to **keys/acme-account-private-key.pem**.

```bash
chmod 600 keys/acme-account-private-key.pem
```

Create a service account in GCP following these [instructions](https://certbot-dns-google.readthedocs.io/en/stable/) and then store the service account json file at **keys/certbot-gcp-service-account.json**

## Retrieve Let's Encrypt CA

The workload cluster needs to use a special oidc plan so that it leverages the DEX OIDC federated endpoint

```bash
curl https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o keys/letsencrypt-ca.pem
chmod 600 keys/letsencrypt-ca.pem
```