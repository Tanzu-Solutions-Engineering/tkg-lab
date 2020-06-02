# Wavefront Tracing with Jaeger

For this section, you will perform the following actions in order to get data flowing through Wavefront proxy, which is already installed on this cluster:

- Modify wavefront deployment to accept jaeger traces
- Deploy jaeger-agent as daemonset into acme-fitness namespace
- Modify YAMLs for acme-fitness and redeploy acme
- Generate traffic with application
- View with Wavefront

## Pre-requisites
To complete this lab, acme-fitness must be running completely as documented within your workload cluster.  Also, you must have ensured that Wavefront was installed successfully and is sending information to Wavefront via the proxy. Finally, you must be using a KUBECONFIG that can make modifications to all namespaces (not cody):

Ensure that your context is set to the workload cluster:

```bash
CLUSTER_NAME=$(yq r params.yaml workload-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

All aspects of acme-fitness should be correct:

```bash
kubectl get po,deployment,cert,ing -n acme-fitness
```

## Modify Wavefront

Re-deploy the Wavefront helm chart with the following script, which enables the "traceJaegerApplicationName" parameter (which you set in params.yaml within the acme-fitness section).  It also enables Wavefront Proxy pre-processor rules, which allow you to modify and add tags to be sent with the trace data.

```bash
./scripts/deploy-wavefront-tracing.sh $CLUSTER_NAME
```

After a moment, the wavefront proxy should be redeployed.  You can check it with:
```bash
kubectl get all -n wavefront
```

## Add Jaaeger Daemonset

By deploying a Jaeger daemonset, the Jaeger agent is running on each node in the cluster.  Applications can point their instrumentation to the IP of the host, which is why we will later modify the acme-fitness deployments to consume the IPs of the host.  For now, install the daemonset in the acme-fitness namespace:

```bash
kubectl apply -f acme-fitness/jaeger-daemonset.yaml -n acme-fitness
```

This will create a pod per worker node that is sending trace data to the wavefront proxy over in its own namespace.  It uses the DNS name of wavefront-proxy.wavefront as the hostname and the port we picked for jaeger traces (30001).

## Modify ACME Fitness deployments

In order to send data from Jaeger to the jaeger-agent pods, we need to modify 6 of the deployments:
- cart-total.yaml
- catalog-total.yaml
- users-total.yaml
- payment-total.yaml
- frontend-total.yaml
- order-total.yaml

All of these are in acme_fitness-demo/kubernetes-manifests.  Perform the following change:

From:
```
        - name: JAEGER_AGENT_HOST
          value: 'localhost'
```
To:
```bash
        - name: JAEGER_AGENT_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
``` 

Redeploy each one after the changes are made
```bash
kubectl apply -f acme-fitness-demo/kubernetes-manifests/cart-total.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/catalog-total.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/users-total.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/payment-total.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/frontend-total.yaml
kubectl apply -f acme-fitness-demo/kubernetes-manifests/order-total.yaml
```
Now hit the application in your browser, with this suggested order:
1) Log in as eric/vmware1!
2) Browse the catalog
3) Put something in the cart
4) Modify the cart (quantity)
5) Checkout (fake data)

Within a few minutes, you should see data flowing into the Wavefront UI that you configured in the Applications -> Application Status area.  The name you selected in params.yaml as the *wavefront.jaeger-app-name-prefix* should be a top level item.  Select that and look for front-end as the service.  All distributed traces go through that service.

NOTE - cluster and shard do not come through as tags without advanced modification.  That is another lesson.


