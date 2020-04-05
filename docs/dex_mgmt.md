# Configure Dex on Management Server

Copy the example modification files over to your working directory.

```bash
cp tkg-extensions-mods-examples/authentication/dex/aws/oidc/03-certs.yaml clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/03-certs.yaml
cp tkg-extensions-mods-examples/authentication/dex/aws/oidc/04-cm.yaml clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/sensitive/04-cm.yaml
```

The modified versions were specific to my environment.  Make the following updates to customize to your environment.

Update clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/03-certs.yaml

Issuer with name=dex-ca-issuer

- spec.acme.server
- spec.acme.email
- spec.acme.solvers[0].dns01.clouddns.project

Certificate with name=dex-cert

- spec.commonName
- spec.dnsNames[0]

Update clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/sensitive/04-cm.yaml

- issuer
- connectors[0].config.issuer
- connectors[0].config.clientID
- connectors[0].config.clientSecret
- connectors[0].config.redirectURI

```bash
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/01-namespace.yaml
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/02-service.yaml
kubectl create secret generic acme-account-key \
   --from-file=tls.key=keys/acme-account-private-key.pem \
   -n tanzu-system-auth
kubectl create secret generic certbot-gcp-service-account \
   --from-file=keys/certbot-gcp-service-account.json \
   -n tanzu-system-auth
# Using modified version below
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/03-certs.yaml
# Using modified version below
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/dex/aws/oidc/sensitive/04-cm.yaml
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/05-rbac.yaml
# Update the below environment variables
export CLIENT_ID=FROM_OKTA_APP
export CLIENT_SECRET=FROM_OKTA_APP
kubectl create secret generic oidc \
   --from-literal=clientId=$(echo -n $CLIENT_ID | base64) \
   --from-literal=clientSecret=$(echo -n $CLIENT_SECRET | base64) \
   -n tanzu-system-auth
watch kubectl get certificate -n tanzu-system-auth
# Wait for above certificate to be ready.  It took me about 2m20s
kubectl apply -f tkg-extensions/authentication/dex/aws/oidc/06-deployment.yaml
```

Get the load balancer external IP for the dex service

```bash
kubectl get svc dexsvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** dex entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```