# Create new Workload Cluster

The example workload cluster leverages common components that were used to create the shared services cluster:

- Creating a workload cluster enabled for OIDC
- Attaching the newly created cluster to TMC
- Applying default policy on the cluster allowing platform-team admin access
- Setting up contour for ingress with a cluster certificate issuer
- Setting up fluent-bit to send logging to the centralized Elasticsearch server on shared services cluster
- Setting up prometheus and grafana for monitoring
- Setting up daily Velero backups

Here we are pulling the following values from the `params.yaml` file.  See examples:

```yaml
workload-cluster:
  worker-replicas: 2
  name: highgarden
  ingress-fqdn: '*.highgarden.tkg-aws-e2-lab.winterfell.live'
  prometheus-fqdn: prometheus.highgarden.tkg-aws-e2-lab.winterfell.live
  grafana-fqdn: grafana.highgarden.tkg-aws-e2-lab.winterfell.live
```

Now you can execute the following script to perform all of those tasks:

```bash
./scripts/deploy-all-workload-cluster-components.sh
```

>Note: Wait until your cluster has been created and components installed. It may take 12 minutes.
>Note: Once cluster is created your kubeconfig already has the new context as the active one with the necessary credentials

## Validation Step

There are lots of potential validation steps, but let's focus on the ability to login.

```bash
tanzu cluster kubeconfig get $(yq e .workload-cluster.name $PARAMS_YAML)
kubectl config use-context tanzu-cli-$(yq e .workload-cluster.name $PARAMS_YAML)@$(yq e .workload-cluster.name $PARAMS_YAML)
kubectl get pods
```

A browser window will launch and you will be redirected to Okta.  Login as `alana`.  You should see the results of your pod request.

## Congrats, Foundational Lab is Complete

You are now welcome to continue on with the Acme Fitness lab, or explore our bonus labs. Visit the [Main Readme](../../Readme.md) to continue.
