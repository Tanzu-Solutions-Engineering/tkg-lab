# Get, update, and deploy Acme-fitness app

## Set configuration parameters

The scripts to prepare the YAML to deploy acme-fitness depend on a parameters to be set.  Ensure the following are set in `params.yaml':

```yaml
acme-fitness:
  fqdn: acme-fitness.highgarden.tkg-aws-e2-lab.winterfell.live
```

## Retrieve acme-fitness source code

```bash
./scripts/retrieve-acme-fitness-source.sh
```

## Prepare Manifests for acme-fitness

Prepare the YAML manifests for customized acme-fitness K8S objects.  Manifests will be output into `generated/$WORKLOAD_CLUSTER_NAME/acme-fitness/` in case you want to inspect.

```bash
./scripts/generate-acme-fitness-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)
```

## Deploy acme-fitness

Once we use our "cody" kubeconfig and set it into the shell, we can update the current context and then avoid specifying namespace for each command below.  These will all apply to the acme-fitness namespace.

```bash
export KUBECONFIG=~/Downloads/kubeconf.txt

ytt \
    --ignore-unknown-comments \
    -f acme-fitness/app-label-overlay.yaml \
    -f acme-fitness/acme-fitness-secrets.yaml \
    -f acme-fitness/acme-fitness-mongodata-pvc.yaml \
    -f acme-fitness/catalog-db-volume-overlay.yaml \
    -f acme_fitness_demo/kubernetes-manifests/cart-redis-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/cart-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/catalog-db-initdb-configmap.yaml \
    -f acme_fitness_demo/kubernetes-manifests/catalog-db-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/catalog-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/frontend-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/payment-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/order-db-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/order-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/users-db-initdb-configmap.yaml \
    -f acme_fitness_demo/kubernetes-manifests/users-db-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/users-redis-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/users-total.yaml \
    -f acme_fitness_demo/kubernetes-manifests/frontend-total.yaml \
    -f generated/$(yq e .workload-cluster.name $PARAMS_YAML)/acme-fitness/acme-fitness-frontend-ingress.yaml | \
    kapp deploy -n acme-fitness -a acme-fitness -y -f -

unset KUBECONFIG
```

### Validation Step

Go to the ingress URL to test out.  

```bash
open https://$(yq r $PARAMS_YAML acme-fitness.fqdn)
# login with eric/vmware1! in order to make a purchase.
```
