# Log-in to workload cluster and setup kubeconfig

1. Login to the workload cluster at https://gangway.wlc-1.tkg-aws-lab.winterfell.live (adjust for your base domain)
2. Click Sign In
3. Log into okta as cody@winterfell.live
4. Give a secret question answer
5. Download kubeconfig
6. Attempt to access wlc-1 cluster with the new config

```bash
export KUBECONFIG=~/Downloads/kubeconf.txt
kubectl config set-context --current --namespace acme-fitness
kubectl get pods
```