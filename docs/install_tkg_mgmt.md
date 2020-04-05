# Install TKG Management Cluster

Follow the docs... for background and pre-requisite tasks.  http://go/tkg-alexandria-docs

1. Complete `Set Up the Bootstrap Environment for Tanzu Kubernetes Grid` which gets your kubectl and docker setup.

2. Complete `Prepare to Deploy the Management Cluster to Amazon EC2` which does setup activity in EC2.  I used the following script which hard codes us-east-2 (but you can change this) and stored the private key at keys/aws-ssh.pem

```bash
./01-prep-aws-objects.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
```

3. Complete `Deploy the Management Cluster to Amazon EC2 with the CLI`.  I have included a config-REDACTED.yaml at the root of this repo.  You can use that as a reference of what my config.yaml ended up looking like after the tasks described in the docs.  Also, here is a script I used to complete the deployment.

```bash
./02-deploy-mgmt-cluster.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY

# Once completed scale the worker nodes for the management cluster
tkg scale cluster tkg-mgmt-aws --namespace tkg-system -w 2
```

## Install Default Storage Class

```bash
kubectl apply -f clusters/mgmt/default-storage-class.yaml
```

## Validation Step

```bash
tkg get management-clusters --config config.yaml
kubectl get pods -A
kubectl sc
```

