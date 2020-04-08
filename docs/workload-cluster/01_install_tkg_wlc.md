# Create new workload cluster

## Set environment variables

The scripts to prepare the YAML to deploy dex depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for dex service
export DEX_CN=dex.mgmt.tkg-aws-lab.winterfell.live
```

## Deploy workload cluster with OIDC plan

```bash

# Note  Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-aws/v0.5.2/
cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-aws/v0.5.2/

export OIDC_ISSUER_URL=https://$DEX_CN
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

tkg create cluster wlc-1 --plan=oidc -w 2 -v 6
```

>Note: Wait until your cluster has been created. It may take 12 minutes.

## Set context to the newly created cluster

```bash
tkg get credentials wlc-1
kubectl config use-context wlc-1-admin@wlc-1
```

## Install Default Storage Class on Workload Cluster

```bash
kubectl apply -f clusters/wlc-1/default-storage-class.yaml
```
