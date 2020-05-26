# Deploy GitLab

Here we will deploy Gitlab via Helmv3 into our workload cluster.  We need to make some modifications to the GitLab values file in order to deploy the chart.  It needs:
- to use Contour instead of Nginx Ingress
- to have the ability to do the HTTP01 challenge (hence we need a DNS entry)
- sclaed down resources

To start, create a namespace using TMC:

```bash

export VMWARE_ID=xxxx
tmc cluster namespace create -c se-cl-${VMWARE_ID}-aws-wlc-1 \
  -n gitlab -d "Gitlab" -k ws-${VMWARE_ID}

```
Ensure that there is a default Storage Class.  This should exist from the other demos in the Workload cluster:

```bash
kubectl get sc
NAME               PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
aws-sc (default)   kubernetes.io/aws-ebs   Delete          Immediate           false                  7d5h
```
Add the *.gitlab entry to the DNS:

```bash
./scripts/update-dns-records-route53.sh *.gitlab
```
Modify the values file within /scripts/values-gitlab.yaml to include the same load balancer name as was used in the CNAME entry and the domain name for gitlab. Also update the email address at the top.  Here is an example:

```yaml
certmanager-issuer:
  email: agregory@pivotal.io # Change Me
...  
global:
  hosts:
    domain: tkg-aws-lab.arg-pivotal.com  # Change Me
    externalIP: ae361b500ddda47a8b9980b9d02155b4-1572019411.us-east-2.elb.amazonaws.com  # Change Me
```

Ensure the helm chart is added to the repo for Helm 3 and let it fly:

```bash
sudo snap install helm
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm repo list
helm upgrade --install gitlab gitlab/gitlab -f scripts/values-gitlab.yaml -n gitlab
```

Wait a few minutes and check the pods, ingresses, and PVCs to make sure they are all good.  Retreive the inital password:

```bash
kubectl get pod,pvc,ing,cert -n gitlab
kubectl get -n gitlab secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

Go to the browser -> https://gitlab.gitlab.tkg-aws-lab.arg-pivotal.com/ and log in with root/<the password>
 
