# Apply image policy

For this demo we will show how Tanzu Mission Control can help lock down allowed images that can be deployed.  The ACME Fitness app should be running already, from the previous step.  For this step, we'll create a policy for TMC which restricts image pulls to only the Harbor registry running in our management cluster.  Then we will delete the Replica Sets and see if they can be restarted (pulled) given the new policy.  Finally, we'll add a policy to all content from the registries that ACME Fitness comes from, and we'll see the application working again.

To begin, create a policy within TMC which restricts us to harbor only:

```bash
export BASE_DOMAIN=xxx.yyy # (Your top-level domain )
export LAB_SUBDOMAIN=tkg-aws-lab.${BASE_DOMAIN}
export VMWARE_ID=<username> # Such as gregoryan

tmc workspace image-policy create \
  --workspace-name=${VMWARE_ID}-acme-fitness-dev \
  --recipe-name=allow-registry \
  --registry-domains=harbor.mgmt.${LAB_SUBDOMAIN} \
  --name=only-harbor

```
Now that we have a policy in place which restricts image pulls only from Harbor, see what happens when we remove the ReplicaSets, and the Deployments attempt to re-pull the images:

```bash
kubectl delete rs -n acme-fitness --all
```

To see which image registries we will need to add, we can show the currently used images within the acme-fitness app:

```bash
grep -r image: acme_fitness_demo/*
acme_fitness_demo/kubernetes-manifests/users-redis-total.yaml:          image: bitnami/redis
acme_fitness_demo/kubernetes-manifests/cart-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-cart:latest
acme_fitness_demo/kubernetes-manifests/order-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-order:latest
acme_fitness_demo/kubernetes-manifests/cart-redis-total.yaml:          image: bitnami/redis
acme_fitness_demo/kubernetes-manifests/catalog-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-catalog:latest
acme_fitness_demo/kubernetes-manifests/users-db-total.yaml:          image: mongo:4
acme_fitness_demo/kubernetes-manifests/users-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-user:latest
acme_fitness_demo/kubernetes-manifests/frontend-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-front-end:latest
acme_fitness_demo/kubernetes-manifests/catalog-db-total.yaml:          image: mongo:4
acme_fitness_demo/kubernetes-manifests/order-db-total.yaml:        image: postgres:9.5
acme_fitness_demo/kubernetes-manifests/point-of-sales-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-pos:v0.1.0-beta
acme_fitness_demo/kubernetes-manifests/jaeger-all-in-one.yml:              image: jaegertracing/all-in-one
acme_fitness_demo/kubernetes-manifests/payment-total.yaml:      - image: gcr.io/vmwarecloudadvocacy/acmeshop-payment:latest
```

Now, within TMC, we can assign image policies to allow the registries being used:
- gcr.io
- docker.io (for all others)

If we add only the GCR repository, then re-run the deployments from the previous step, we should see that only some of the deployment will start:

<image from TMC UI>

```bash
kubectl get deployment -n acme-fitness
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
cart             0/1     0            0           27s
cart-redis       1/1     1            1           28s
catalog          0/1     0            0           26s
catalog-mongo    1/1     1            1           26s
frontend         0/1     0            0           23s
order            0/1     0            0           25s
order-postgres   1/1     1            1           25s
payment          0/1     0            0           26s
users            0/1     0            0           23s
users-mongo      1/1     1            1           24s
users-redis      1/1     1            1           24s
```

After seeing this, go back and add the other registry (GCR).  A couple minutes later, the deployments will have pods running.


The other thing we can do is use our harbor registry with a private repository.  What we would do is pull all imagees locally, re-tag the images, and push them to harbor.  We'd then update the deployment YAML files to specify the images as the new harbor-based locations.  We'd also define a Pull Secret, which would contain the Harbor credentials needed to pull.  It also works with a public Harbor repository and no pull secret needed. 
