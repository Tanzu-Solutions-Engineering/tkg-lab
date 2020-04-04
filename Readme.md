# TKG Lab

![TKG Lab Deployment Diagram](docs/tkg-deployment.png)

## Required CLIs

- kubectl
- tmc
- tkg
- velero
- helm 3

## Install TKG Management Cluster

Follow the docs... for background and pre-requisite tasks.  http://go/tkg-alexandria-docs

1. Complete `Set Up the Bootstrap Environment for Tanzu Kubernetes Grid` which gets your kubectl and docker setup.

2. Complete `Prepare to Deploy the Management Cluster to Amazon EC2` which does setup activity in EC2.  I used the following script which hard codes us-east-2 (but you can change this) and stored the private key at keys/aws-ssh.pem

```bash
./01-prep-aws-objects.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
```

3. Complete `Deploy the Management Cluster to Amazon EC2 with the CLI`.  I have included a config-REDACTED.yaml at the root of this repo.  You can use that as a reference of what my config.yaml ended up looking like after the tasks described in the docs.  Also, here is a script I used to complete the deployment.

```bash
./02-deploy-mgmt-cluster.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
```

### Validation Step

```bash
tkg get management-clusters --config config.yaml
kubectl get pods -A
```

## Temporary Fix.  Update Root Volume Disk Size of Management Cluster

1. In AWS select the management control-plane instance.  In the details, click the `Root device` hyperlink, then click on the EBS ID hyperlink, which will bring you to a list view that shows you have 8 GiB Size

2. With this volume selected, choose Actions->Modify Volume.  Change size to 40 and choose Modify button, and Yes button at the warning.

3. Now you need to ssh into the control-plane vm and issue the commands to grow the volume.

```bash
export JUMPBOX_IP=3.21.98.10
scp -i keys/aws-ssh.pem -o "StrictHostKeyChecking=no" keys/aws-ssh.pem ubuntu@$JUMPBOX_IP:/home/ubuntu/aws-ssh.pem 
ssh -i keys/aws-ssh.pem ubuntu@$JUMPBOX_IP 
ssh -i aws-ssh.pem ec2-user@10.0.0.59 -o "StrictHostKeyChecking=no"
lsblk
sudo growpart /dev/nvme0n1 1
lsblk
```

4. Repeat for the management cluster worker node

5. Using EC2 console reboot all nodes

## Attach Management Cluster to TMC

```bash
export VMWARE_ID=YOUR_ID
tmc cluster attach \
  --name se-$VMWARE_ID-mgmt \
  --labels origin=$VMWARE_ID \
  --group se-$VMWARE_ID-dev-cg \
  --output clusters/mgmt/sensitive/tmc-mgmt-cluster-attach-manifest.yaml
kubectl apply -f clusters/mgmt/sensitive/tmc-mgmt-cluster-attach-manifest.yaml
```

### Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes but appear clean.

## Setup DNS

I chose Google Cloud DNS because it has a supporting Let's Encrypt Certbot Plugin.

```bash
export BASE_DOMAIN=YOUR_BASE_DOMAIN
#export BASE_DOMAIN=winterfell.live
gcloud dns managed-zones create tkg-aws-lab \
  --dns-name tkg-aws-lab.$BASE_DOMAIN. \
  --description "TKG AWS Lab domains"
```

## Setup a Let's Encrypt Account

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

## Setup an account with Okta for OpenID Connect (OIDC)

Setup a free Okta account: https://developer.okta.com/signup/

Once logged in...

Choose Users->People from the top menu.

Add People.  For each user, Password Set by Admin, YOUR_PASSWORD, Uncheck user must change password:

- Alana Smith, alana@winterfell.live

Choose Users->Groups from the top menu.

Add Groups:

- platform-team

Click on platform-team group
Click Manage People, then add alana to the platform-team

Choose Applications from top menu.

Choose Web, Next.

Give your app a name: TKG
Remove Base URL
Login redirect URIs: https://dex.mgmt.tkg-aws-lab.winterfell.live/callback
Logout redirect URIs: https://dex.mgmt.tkg-aws-lab.winterfell.live/logout	
Grant type allowed: Authorization Code

> Note: Use your root domain above

Click Done button

Capture ClientID and Client Secret

Go to API->Authorization Servers on the top menu

Click on the `default` authorization Server

Click on Scopes tab, then Add Scope name=groups and mark include in public metadata

Click on Claims tab, then Add Claim 
  - name=groups
  - Include in toke type=ID Token
  - value type=Groups
  - Filter Matches regex => .*
  - Include in= The following scopes `groups`

On the top left, Choose the arrow next to Developer Console and choose Classic UI

Go to Applications->Applications

Pick your app

Pick Sign On sub tab of the app

Click the Edit button associated with **OpenID Connect ID Token**
Groups claim type => Filter
Groups claim filter => **groups** Matches regex **.\***

## Retrieve TKG Extensions

The TKG Extensions are available at https://gitlab.eng.vmware.com/TKG/tkg-extensions.  We are going to retrieve the latest version and then commit them to this repo so that we can track changes.  In following sections we will be replacing some of the files form a folder in the tkg-extensions-mods/ folder.

```bash
git clone https://gitlab.eng.vmware.com/TKG/tkg-extensions
rm -rf tkg-extensions/.git
```

## Configure Dex on Management Server

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

## Install Tanzu Observability by WaveFront on the management cluster

Use your Pivotal Okta to get into wavefront, and then retrieve your API_KEY.
Assuming you have helm3 installed.

```bash
export TO_API_KEY=YOUR_API_KEY
export VMWARE_ID=YOUR_VMWARE_ID
kubectl create namespace wavefront
helm repo add wavefront https://wavefronthq.github.io/helm/
helm repo update
helm install wavefront wavefront/wavefront \
  --set wavefront.url=https://surf.wavefront.com \
  --set wavefront.token=$TO_API_KEY \
  --set clusterName=$VMWARE_ID-mgmt \
  --namespace wavefront
```

### Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID-mgmt cluster.

## Install Contour on management cluster

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```

Get the load balancer external IP for the envoy service

```bash
kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** wildcard management `*.mgmt` entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```

## Install Default Storage Class

```bash
kubectl apply -f clusters/mgmt/default-storage-class.yaml
```

## Install elastic search and kibana

> Note: Update the kibana ingress in `clusters/mgmt/elastic-search-kibana/04-kibana.yaml` to refer to your base domain.  It currently has mine.

```bash
kubectl apply -f clusters/mgmt/elastic-search-kibana/01-namespace.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/02-statefulset.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/03-service.yaml
kubectl apply -f clusters/mgmt/elastic-search-kibana/04-kibana.yaml
```

Get the load balancer external IP for the elasticsearch service

```bash
kubectl get svc elasticsearch -n tanzu-system-logging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** elasticsearch entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```

### Validation Step

Ensure all pods are in running state.

```bash
kubectl get pods -n tanzu-system-logging
```

Get an response back from elasticsearch rest interface

```bash
curl -v http://elasticsearch.mgmt.tkg-aws-lab.winterfell.live:9200
```

## Install fluent bit

```bash
cp tkg-extensions-mods-examples/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
```

Update clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml.  Find *elasticsearch.mgmt.tkg-aws-lab.winterfell.live* and replace with your elasticsearch URL.

```bash
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/00-fluent-bit-namespace.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/01-fluent-bit-service-account.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/02-fluent-bit-role.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/03-fluent-bit-role-binding.yaml
# Using modified version below
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/05-fluent-bit-ds.yaml
```

## Validation Step

Ensure that fluent bit pods are running

```bash
kubectl get pods -n tanzu-system-logging
```

Access kibana.  This leverages the wildcard DNS entry on the convoy ingress.  Your base domain will be different than mine.

```bash
open http://logs.mgmt.tkg-aws-lab.winterfell.live
```

You should see the kibana welcome screen.  

Click the Discover icon at the top of the right menu bar.

You will see widget to create an index pattern.  Enter `logstash-*` and click `next step`.

Select `@timestamp` for the Time filter field name. and then click `Create index pattern`

Now click the Discover icon at the top of the right menu bar.  You can start searching for logs.

## Install Velero and Setup Nightly Backup

brew install velero

Follow [Velero Plugins for AWS Guide](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup).  I chose **Option 1** for **Set Permissions for Veloro Step**.

Store your credentials-velero file in keys/

Go to AWS console S3 service and create a bucket for backups.

One more step is required or else the cluster backups will fail.  Cert-manager has a broken reference where the clusterrolebinding cert-manager-leaderelection references a clusterrole cert-manager-leaderelection that does not exist.  This causes the backup to partially fail.  So we will go ahead and delete this invalid clusterrolebinding.

Now install velero on the management cluster and schedule nightly backup

```bash
kubectl delete clusterrolebinding cert-manager-leaderelection
export VELERO_BUCKET=YOUR_BUCKET_NAME
export REGION=YOUR_REGION
export CLUSTER_NAME=mgmt
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.1 \
    --bucket $VELERO_BUCKET \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION \
    --secret-file keys/credentials-velero
velero schedule create daily-$CLUSTER_NAME-cluster-backup --schedule "0 7 * * *"
velero backup get
velero schedule get
```

## Now you have a simulated request to setup cluster for a new team

## Create new workload cluster

The workload cluster needs to use a special oidc plan so that it leverages the DEX OIDC federated endpoint

```bash

curl https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o keys/letsencrypt-ca.pem
chmod 600 keys/letsencrypt-ca.pem


## Double check the version number below incase it has changed - ~/.tkg/providers/infrastructure-aws/v0.5.1/
cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-aws/v0.5.1/

export OIDC_ISSUER_URL=https://dex.mgmt.tkg-aws-lab.winterfell.live
export OIDC_USERNAME_CLAIM=email
export OIDC_GROUPS_CLAIM=groups
# Note: This is different from the documentation as dex-cert-tls does not contain letsencrypt ca
export DEX_CA=$(cat keys/letsencrypt-ca.pem | gzip | base64)

tkg create cluster wlc-1 --plan=oidc --config config.yaml -w 2 -v 6
```

>Note: Wait until your cluster has been created. It may take 12 minutes.

## Install Default Storage Class

```bash
kubectl apply -f clusters/wlc-1/default-storage-class.yaml
```

## Setup Group and Users in Okta

Go to your Okta Console.  Mine is https://dev-866145-admin.okta.com/dev/console.

Once logged in...

Choose Users->People from the top menu.

Add People.  For each user, Password Set by Admin, YOUR_PASSWORD, Uncheck user must change password:

- Cody Smith, cody@winterfell.live
- Naomi Smith, naomi@winterfell.live

Choose Users->Groups from the top menu.

Add Groups:

- acme-fitness-devs

Click on acme-fitness-devs group
Click Manage People, then add naomi and cody to the acme-fitness-devs

## Install Cert Manager

```bash
kubectl apply -f tkg-extensions/cert-manager/
```

## Install Gangway

Copy the example modification files over to your working directory.

```bash
cp tkg-extensions-mods-examples/authentication/gangway/aws/03-config.yaml clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/03-config.yaml
cp tkg-extensions-mods-examples/authentication/gangway/aws/05-certs.yaml clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/05-certs.yaml
```

Modified versions of ganway config files were specific to my environment.  Make the following updates to customize to your environment.

Update clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/05-certs.yaml

Issuer with name=dex-ca-issuer

- spec.acme.server
- spec.acme.email
- spec.acme.solvers[0].dns01.clouddns.project

Certificate with name=dex-cert

- spec.commonName
- spec.dnsNames[0]

Update clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/03-config.yaml

- authorizeURL (just update the root domain name)
- tokenURL (just update the root domain name)
- redirectURL (just update the root domain name)
- apiServerURL (retrieve the wlc-1 api server url from your kubeconfig)

```bash
kubectl apply -f tkg-extensions/authentication/gangway/aws/01-namespace.yaml
kubectl apply -f tkg-extensions/authentication/gangway/aws/02-service.yaml
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/03-config.yaml
# Below is FOO_SECRET intentionally hard coded
kubectl create secret generic gangway \
   --from-literal=sesssionKey=$(openssl rand -base64 32) \
   --from-literal=clientSecret=FOO_SECRET \
   -n tanzu-system-auth
kubectl create secret generic acme-account-key \
   --from-file=tls.key=keys/acme-account-private-key.pem \
   -n tanzu-system-auth
kubectl create secret generic certbot-gcp-service-account \
   --from-file=keys/certbot-gcp-service-account.json \
   -n tanzu-system-auth
kubectl apply -f clusters/mgmt/tkg-extensions-mods/authentication/gangway/aws/05-certs.yaml
watch kubectl get certificate -n tanzu-system-auth
# Wait for above certificate to be ready.  It took me about 2m20s
kubectl create cm dex-ca -n tanzu-system-auth --from-file=dex-ca.crt=keys/letsencrypt-ca.pem
kubectl apply -f tkg-extensions/authentication/gangway/aws/06-deployment.yaml
```

Get the load balancer external IP for the gangway service

```bash
kubectl get svc gangwaysvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** gangway entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```

## Attach the new workload cluster to TMC

```bash
export VMWARE_ID=dpfeffer
tmc cluster attach \
  --name pa-$VMWARE_ID-wlc-1 \
  --labels origin=$VMWARE_ID \
  --group pa-$VMWARE_ID-dev-cg \
  --output clusters/wlc-1/sensitive/tmc-wlc-1-cluster-attach-manifest.yaml
kubectl apply -f clusters/wlc-1/sensitive/tmc-wlc-1-cluster-attach-manifest.yaml
```

### Validation Step

Go to the TMC UI and find your cluster.  It should take a few minutes but appear clean.

```bash
# Replace pa-dpfeffer-mgmt with the name of your management cluser
tmc cluster iam add-binding pa-dpfeffer-mgmt --role cluster.admin --groups platform-team
```

### Validation Step

1. Access TMC UI
2. Select Policies on the left nav
3. Choose Access->Clusters and then select your wlc-1 cluster
4. Observer direct Access Policy => Set cluster.admin permission to the platform-team group
5. Login to the workload cluster at https://gangway.wlc-1.tkg-aws-lab.winterfell.live (adjust for your base domain)
6. Click Sign In
7. Log into okta as alana@winterfell.live
8. Give a secret password
9. Download kubeconfig
10. Attempt to access wlc-1 cluster with the new config

```bash
KUBECONFIG=~/Downloads/kubeconf.txt kubectl get pods -A
```

## Use TMC to set workspace and Access Policy for acme-fitness

Use the commands below to create a workspace and associated namespace.  Then provide the workspace.edit role to the acme-fitness-dev group.

>Note: update the files within tmc/config to match your specific names.  Essentially replace the dpfeffer references with your own.

```bash
tmc workspace create -f tmc/config/workspace/acme-fitness-dev.yaml
tmc cluster namespace create -f tmc/config/namespace/tkg-mgmt-acme-fitness.yaml
tmc workspace iam add-binding dpfeffer-acme-fitness-dev --role workspace.edit --groups acme-fitness-devs
```

## Set Resource Quota for acme-fitness namespace

```bash
kubectl apply -f clusters/wlc-1/acme-fitness-namespace-quota.yaml
```

## Install fluent bit


```bash
cp tkg-extensions-mods-examples/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
```

Update clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml.  Find *elasticsearch.mgmt.tkg-aws-lab.winterfell.live* and replace with your elasticsearch URL.

```bash
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/00-fluent-bit-namespace.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/01-fluent-bit-service-account.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/02-fluent-bit-role.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/03-fluent-bit-role-binding.yaml
# Using modified version below
kubectl apply -f clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/05-fluent-bit-ds.yaml
```

## Install Tanzu Observability by WaveFront on the workload cluster

Use your Pivotal Okta to get into wavefront, and then retrieve your API_KEY.
Assuming you have helm3 installed.

```bash
export TO_API_KEY=YOUR_API_KEY
export VMWARE_ID=YOUR_VMWARE_ID
kubectl create namespace wavefront
helm install wavefront wavefront/wavefront \
  --set wavefront.url=https://surf.wavefront.com \
  --set wavefront.token=$TO_API_KEY \
  --set clusterName=$VMWARE_ID-wlc-1 \
  --namespace wavefront
```

### Validation Step

Follow the URL provided in the helm install command and filter the cluster list to your $VMWARE_ID-wlc-1 cluster.

## Install Contour on workload cluster

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
kubectl create secret generic acme-account-key \
   --from-file=tls.key=keys/acme-account-private-key.pem \
   -n tanzu-system-ingress
kubectl apply -f clusters/wlc-1/contour-cluster-issuer.yaml
```

Get the load balancer external IP for the envoy service

```bash
kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** wildcard management `*.wlc-1` entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```

## Install Velero and Setup Nightly Backup

Go to AWS console S3 service and create a bucket for wlc-1 backups.

Now install velero on the wlc-1 cluster and schedule nightly backup

```bash
export VELERO_BUCKET=YOUR_BUCKET_NAME
export REGION=YOUR_REGION
export VELERO_BUCKET=pa-dpfeffer-wlc-1-velero
export REGION=us-east-2
export CLUSTER_NAME=wlc-1
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.0.1 \
    --bucket $VELERO_BUCKET \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION \
    --secret-file keys/credentials-velero
velero schedule create daily-$CLUSTER_NAME-cluster-backup --schedule "0 7 * * *"
velero backup get
velero schedule get
```

## Now Switch to Acme-Fitness Dev Team Perspective

## Get Log-in and setup kubeconfig

1. Login to the workload cluster at https://gangway.wlc-1.tkg-aws-lab.winterfell.live (adjust for your base domain)
2. Click Sign In
3. Log into okta as cody@winterfell.live
4. Give a secret question answer
5. Download kubeconfig
6. Attempt to access wlc-1 cluster with the new config

```bash
export KUBECONFIG=~/Downloads/kubeconf.txt
export kubectl config set-context --current --namespace acme-fitness
kubectl get pods
```

## Get, update, and deploy Acme-fitness

```bash
git clone https://github.com/vmwarecloudadvocacy/acme_fitness_demo.git
cd acme_fitness_demo
git checkout 158bbe2
cd ..
rm -rf acme_fitness_demo/.git
rm -rf acme_fitness_demo/aws-fargate
rm -rf acme_fitness_demo/docker-compose
```

```bash
kubectl apply -f clusters/wlc-1/acme-fitness/acme-fitness-mongodata-pvc.yaml
kubectl create secret generic cart-redis-pass --from-literal=password=KeepItSimple1! --namespace acme-fitness
kubectl label secret cart-redis-pass app=acmefit
kubectl apply -f acme_fitness_demo/kubernetes-manifests/cart-redis-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/cart-total.yaml --namespace acme-fitness
kubectl create secret generic catalog-mongo-pass  --from-literal=password=KeepItSimple1! --namespace acme-fitness
kubectl label secret catalog-mongo-pass app=acmefit
kubectl create -f acme_fitness_demo/kubernetes-manifests/catalog-db-initdb-configmap.yaml --namespace acme-fitness
kubectl label cm catalog-initdb-config app=acmefit
kubectl apply -f acme_fitness_demo/kubernetes-manifests/catalog-db-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/catalog-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/payment-total.yaml --namespace acme-fitness
kubectl create secret generic order-postgres-pass --from-literal=password=KeepItSimple1! --namespace acme-fitness
kubectl label secret order-postgres-pass app=acmefit
kubectl apply -f acme_fitness_demo/kubernetes-manifests/order-db-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/order-total.yaml --namespace acme-fitness
kubectl create secret generic users-mongo-pass --from-literal=password=KeepItSimple1! --namespace acme-fitness
kubectl label secret users-mongo-pass app=acmefit
kubectl create secret generic users-redis-pass --from-literal=password=KeepItSimple1! --namespace acme-fitness
kubectl label secret users-redis-pass app=acmefit
kubectl create -f acme_fitness_demo/kubernetes-manifests/users-db-initdb-configmap.yaml --namespace acme-fitness
kubectl label cm users-initdb-config app=acmefit
kubectl apply -f acme_fitness_demo/kubernetes-manifests/users-db-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/users-redis-total.yaml --namespace acme-fitness
kubectl apply -f acme_fitness_demo/kubernetes-manifests/users-total.yaml --namespace acme-fitness
kubectl patch deployment catalog-mongo  --type merge -p "$(cat clusters/wlc-1/acme-fitness/catalog-db-patch-volumes.yaml)"
kubectl apply -f acme_fitness_demo/kubernetes-manifests/frontend-total.yaml --namespace acme-fitness
kubectl apply -f clusters/wlc-1/acme-fitness/acme-fitness-frontend-ingress.yaml
kubectl label secret acme-fitness-tls app=acmefit
```

### Validation Step

Go to the ingress URL to test out.  Mine is https://acme-fitness.wlc-1.tkg-aws-lab.winterfell.live.

## Teardown

```bash
tmc cluster delete pa-dpfeffer-mgmt
tmc cluster delete pa-dpfeffer-wlc-1
kubectl delete all,secret,cm,ingress,pvc -l app=acmefit
```

## TODO

- Set network access policy for acme-fitness
- Use bitnami for elastic search
