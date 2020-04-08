# Install Harbor Image Registry

### Set environment variables
The scripts to prepare the YAML to deploy Harbor depend on a few environmental variables to be set.  Set the following variables in you terminal session:
```bash
# the email registered with ACME
export EMAIL=dpfeffer@pivotal.io
# the GCP Cloud DNS project ID
export PROJECT_ID=fe-dpfeffer
# the DNS NC to be used for harbor services
export HARBOR_CN=harbor.mgmt.tkg-aws-lab.winterfell.live
# the DNS CN to be used for notary services
export NOTARY_CN=notary.mgmt.tkg-aws-lab.winterfell.live
```
### Prepare Manifests
Prepare the YAML manifests for the related Harbor K8S objects.  Manifest will be output into `clusters/mgmt/harbor/generated/` in case you want to inspect.
```bash
./clusters/mgmt/harbor/00-generate_yaml.sh
```
### Create Create Harbor namespace
```bash
kubectl apply -f clusters/mgmt/harbor/generated/01-namespace.yaml
```
### Create k8s secrets and certificates
We will utizize keys generated in earlier steps.  Replicate these secretes into the harbor namespace:
```bash
kubectl create secret generic certbot-gcp-service-account --from-file=keys/certbot-gcp-service-account.json -n harbor

kubectl create secret generic acme-account-key --from-file=tls.key=keys/acme-account-private-key.pem -n harbor

kubectl apply -f clusters/mgmt/harbor/generated/02-certs.yaml 
```

### Add helm repo and install harbor
```bash
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor -f clusters/mgmt/harbor/generated/harbor-values.yaml --namespace harbor
```

## Validation Step
1. The signed harbor ceritificate should become ready:
```bash
kubectl get certificate -n harbor 
```
2. All harbor pods are in a running state:
```bash
kubectl get po -n harbor 
```
3. Open a browser and navigate to https://<$HARBOR_CN>.  The default user is admin and pwd is Harbor12345
It will take a few minutes, but the 
