# Log-in to workload cluster as developer and setup kubeconfig

## Log out of your alana context

You may already have a session established as alana, the admin user.  If so, perform the following steps.

1. Go to okta using your okta domain and if you are logged in, then perform a log out
2. Delete your local tanzu pinniped session

```bash
rm -rf ~/.config/tanzu/pinniped/
```

## Login As Cody

```bash
tanzu cluster kubeconfig get $(yq e .workload-cluster.name $PARAMS_YAML)
kubectl config use-context tanzu-cli-$(yq e .workload-cluster.name $PARAMS_YAML)@$(yq e .workload-cluster.name $PARAMS_YAML)
# At login prompt, login with your development user: cody
kubectl get pods -n acme-fitness
```

>Note: If you get "No resources found in acme-fitness namespace." then you successfully logged in.  Meaning you have permission to get resources in this namespace.

## Go to Next Step

[Get, update, and deploy Acme-fitness app](04-deploy-app.md)
