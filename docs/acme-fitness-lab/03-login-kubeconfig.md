# Log-in to workload cluster and setup kubeconfig

1. (Using Incognito Window) Login to the workload cluster at https://$(yq r $PARAMS_YAML workload-cluster.gangway-fqdn)
2. Click Sign In
3. Log into okta as cody
4. Give a secret question answer
5. Download kubeconfig
6. Attempt to access workload-cluster cluster with the new config

```bash
KUBECONFIG=~/Downloads/kubeconf.txt kubectl get pods -n acme-fitness
open https://$(yq r $PARAMS_YAML workload-cluster.gangway-fqdn)
```

>Note: If you get "No resources found in acme-fitness namespace." then you successfully logged in.  Meaning you have permission to get resources in this namespace.

## Go to Next Step

[Get, update, and deploy Acme-fitness app](04-deploy-app.md)
