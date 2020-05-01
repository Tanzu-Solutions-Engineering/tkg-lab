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

At this point Kubernetes will try to repull the images and fail due to the policy.  To see the failures and then see which image registries we will need to add, we can show the currently used images within the acme-fitness appi YAML files.  Note that images that simply specify the name of the image imply docker.io as the registry:

```bash
kubectl describe rs -n acme-fitness |egrep "Name|Error creating"

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

If we add only the docker.io repository, then re-run the deployments from the previous step, we should see that only some of the deployment will start:

```bash
tmc workspace image-policy create \
  --workspace-name=${VMWARE_ID}-acme-fitness-dev \
  --recipe-name=allow-registry \
  --registry-domains=docker.io \
  --name=allow-docker-io

kubectl delete rs -n acme-fitness --all

kubectl get rs -n acme-fitness
NAME                        DESIRED   CURRENT   READY   AGE
cart-864dcdc8cc             1         0         0       28s
cart-redis-75b6495979       1         1         1       28s
catalog-6bbd5cb96b          1         0         0       28s
catalog-mongo-65dd975f54    1         1         0       28s
frontend-85cd99f4c6         1         0         0       28s
order-54584897d7            1         0         0       28s
order-postgres-5df88dfb69   1         1         1       28s
payment-79978664d4          1         0         0       28s
users-68bcbbbbcd            1         0         0       27s
users-mongo-d9876d8d6       1         1         1       27s
users-redis-7fd9759bd5      1         1         1       27s
```

After seeing this, go back and add the other registry (GCR).  A couple minutes later, the deployments will have pods running.

```bash
tmc workspace image-policy create \
  --workspace-name=${VMWARE_ID}-acme-fitness-dev \
  --recipe-name=allow-registry \
  --registry-domains=docker.io \
  --name=allow-docker-io

kubectl delete rs -n acme-fitness --all

kubectl get rs -n acme-fitness
NAME                        DESIRED   CURRENT   READY   AGE
cart-864dcdc8cc             1         1         1       2m49s
cart-redis-75b6495979       1         1         1       2m49s
catalog-6bbd5cb96b          1         1         1       2m49s
catalog-mongo-65dd975f54    1         1         1       2m49s
frontend-85cd99f4c6         1         1         1       2m49s
order-54584897d7            1         1         1       2m49s
order-postgres-5df88dfb69   1         1         1       2m49s
payment-79978664d4          1         1         1       2m49s
users-68bcbbbbcd            1         1         1       2m49s
users-mongo-d9876d8d6       1         1         1       2m49s
users-redis-7fd9759bd5      1         1         1       2m48s
```
Another other thing we could have done was use our harbor registry with a private repository.  What we would do is pull all imagees locally, re-tag the images, and push them to harbor.  We'd then update the deployment YAML files to specify the images as the new harbor-based locations.  We'd also define a Pull Secret, which would contain the Harbor credentials needed to pull.  It also works with a public Harbor repository and no pull secret needed. 
