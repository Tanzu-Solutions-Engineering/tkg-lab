# Log-in to workload cluster and setup kubeconfig

```bash
tanzu cluster kubeconfig get $(yq e .workload-cluster.name $PARAMS_YAML)
kubectl config use-context tanzu-cli-$(yq e .workload-cluster.name $PARAMS_YAML)@$(yq e .workload-cluster.name $PARAMS_YAML)
kubectl get pods -n acme-fitness
```

>Note: If you get "No resources found in acme-fitness namespace." then you successfully logged in.  Meaning you have permission to get resources in this namespace.

## Go to Next Step

[Get, update, and deploy Acme-fitness app](04-deploy-app.md)
