# Create new workload cluster

## Set environment variables

The scripts to prepare the YAML to deploy dex depend on a few environmental variables to be set.  Set the following variables in you terminal session:

```bash
# the DNS CN to be used for dex service
export DEX_CN=dex.mgmt.tkg-aws-lab.winterfell.live
```

## Prepare the OIDC plan

For AWS
```bash
# Note  Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-aws/v0.5.2/
cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-aws/v0.5.2/

```

For vSphere
```bash
# Note  Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-vsphere/v0.6.3/
cp tkg-extensions/authentication/dex/vsphere/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-vsphere/v0.6.3/
```

## Deploy workload cluster with OIDC plan

```bash
export OIDC_ISSUER_URL=https://$DEX_CN
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

tkg create cluster wlc-1 --plan=oidc -w 2 -v 6
```

>Note: Wait until your cluster has been created. It may take 12 minutes.
>Note: Once cluster is created your kubeconfig already has the new context as the active one with the necessary credential

## Install Default Storage Class on Workload Cluster

For AWS
```bash
kubectl apply -f clusters/wlc-1/default-storage-class-aws.yaml
```

For vSphere
```bash
kubectl apply -f clusters/wlc-1/default-storage-class-vsphere.yaml
```
