# Install and configure ArgoCD

### Prerequisites
1. Create a Storage Class in your Guest Cluster where you will be running the ArgoCD controller in.
2. Configure or setup a Kubernetes Cloud Load Balancer such as MetalLB.


### Install ArgoCD

Based on the following https://argoproj.github.io/argo-cd/getting_started/

```bash
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 
```

On a Linux or MAC Machine with network access to Kubernetes clusters,  download the latest ArgoCD CLI from https://github.com/argoproj/argo-cd/releases/latest. 

```bash
wget https://github.com/argoproj/argo-cd/releases/download/v1.5.5/argocd-linux-amd64 .
chmod +x argocd-linux-amd64
mv argocd-linux-amd64 /usr/local/bin/argocd
argocd --help
```

Configure ArgoCD

```bash
kubectl get svc -n argocd
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
  argocd-server-656f9b895b-6n746
```
Copy the current password returned from above command. 
```bash
kubectl get svc -n argocd
argocd login 10.51.0.24
    Username: admin
    Password: <SEE ABOVE>
```

Optional - To change your ArgoCD password 
```bash
argocd account update-password
```

Add your Kubernetes cluster to the ArgoCD Controller. Note it must already be configured in your Kubeconfig file.
```bash
argocd cluster add
argocd cluster add argocd
```

### Test ArgoCD Installation

Deploy ArgoCD guestbook example application

```bash
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://192.168.40.107:6443 --dest-namespace default --sync-policy automated
    application 'guestbook' created
    
argocd app list
  NAME       CLUSTER                      NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                                                 PATH       TARGET
  guestbook  https://192.168.40.107:6443  default    default  Synced  Healthy  <none>      <none>      https://github.com/argoproj/argocd-example-apps.git  guestbook
```
Change ArgoCD guestbook example application Service type to LoadBalancer


```bash
1. kubectl patch svc guestbook-ui -p '{"spec": {"type": "LoadBalancer"}}'
2. service/guestbook-ui patched
```
Test access to the ArgoCD Web UI

```bash
kubectl get svc -n argocd
    argocd        argocd-server              LoadBalancer   100.64.104.223   192.168.40.201   80:30962/TCP,443:32173/TCP   33m
```
Get External-IP Address for the   <argocd-server>  service in the <argocd>  Namespace

1. In Chrome, navigate to the UI on External IP Address, here its 192.168.40.201 : 80
2. Login with 
    1. admin and the password you set earlier.
3. Click on the guestbook app you created from the argocd CLI and investigate it 
