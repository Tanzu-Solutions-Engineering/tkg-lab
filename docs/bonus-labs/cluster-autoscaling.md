# Cluster Autoscaling

Tanzu Kubernetes Grid supports cluster autoscaling leveragin the Cluster API provider.  Depending on your lab configuration, you may have enabled cluster autoscaling when your clusters were provisioned.

## Lab Configuration Parameters

You may have noticed the following keys in `params.yaml` that direct the use of cluster autoscaling for the shared services cluster and workload cluster.

General purpose information on how cluster autoscaler works can be found in the upstream [FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md).

```yaml
shared-services-cluster.autoscaler-enabled: true
shared-services-cluster.worker-replicas: 2 # initial and minimum number of worker nodes
shared-services-cluster.worker-replicas-max: 4 # maximum number of worker nodes
workload-cluster.autoscaler-enabled: true
workload-cluster.worker-replicas: 1
workload-cluster.worker-replicas-max: 3
```

## Run the Exercises

For this lab, we will use the shared services cluster to exercise the capability, however you could equally run the commands on the workload cluster.

The following series of commands demonstrate cluster autoscaling...

```bash

# Choosing to use shared services cluster for the command sequence
DEMO_CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
WILD_CARD_FQDN=$(yq e .shared-services-cluster.ingress-fqdn $PARAMS_YAML)

tanzu cluster get $DEMO_CLUSTER_NAME
# see current number of workers

kubectl config use-context $DEMO_CLUSTER_NAME-admin@$DEMO_CLUSTER_NAME

# create new sample app from Kubernetes Up And Running (really could be any app)
kubectl create ns kuard

mkdir -p generated/$DEMO_CLUSTER_NAME/kuard
cp kuard/* generated/$DEMO_CLUSTER_NAME/kuard

export KUARD_FQDN=kuard.$(echo "$WILD_CARD_FQDN" | sed -e "s/^*.//")

yq e -i '.spec.rules[0].host = env(KUARD_FQDN)' generated/$DEMO_CLUSTER_NAME/kuard/ingress.yaml

kubectl apply -f generated/$DEMO_CLUSTER_NAME/kuard -n kuard

# open browser accessing sample app
open http://$KUARD_FQDN

# scale deployment
kubectl get nodes
# notice 2
kubectl scale deployment kuard --replicas 15 -n kuard
kubectl get po -n kuard
# notice pending pods
# switch context to MC
MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME
# check out the autoscaler pod logs in default namespace
kubectl get pods
# check out the machines.  A new one should be provisioning
kubectl get machines

# switch back to demo cluster
kubectl config use-context $DEMO_CLUSTER_NAME-admin@$DEMO_CLUSTER_NAME

# wait for additional nodes to be ready
kubectl get nodes

# when additional nodes are ready, pending pods should now be running
kubectl get pods -n kuard -o wide

# scale back down.  if you wait 10 minutes or so the added nodes should be removed.
kubectl scale deployment kuard --replicas 1 -n kuard

```