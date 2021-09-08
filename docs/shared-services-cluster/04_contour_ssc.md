# Install Contour on Shared Services Cluster

## Deploy Cert Manager

Our solution leverages cert manager to generate valid ssl certs.  Cert-manager was deployed automatically into the management cluster, however it an optional component for workload clusters.  Use this script to deploy cert manager into the cluster using TKG packages.

```bash
./scripts/deploy-cert-manager.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Deploy Contour

Generate and apply Contour configuration. We sepecifically specify type=LoadBalancer for Envoy.  Use the script to apply manifests.

```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Verify Contour

Once it is deployed, you can see all pods `Running` and the the Load Balancer up.  

```bash
kubectl get pod,svc -n tanzu-system-ingress
```

## Setup DNS for Wildcard Domain Contour Ingress

Just as we did for the management cluster, we will leverage [external-dns](https://github.com/kubernetes-sigs/external-dns) for kubernetes managed DNS updates. Same choice of DNS Provider will be used.

Execute the script below to deploy `external-dns` and to apply the annotation to the envoy service.

```bash
./scripts/generate-and-apply-external-dns-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `generated/$CLUSTER_NAME/contour/` in case you want to inspect. It is assumed that if you IaaS is AWS, then you will use the `http` challenge type and if your IaaS is vSphere, you will use the `dns` challenge type as a non-internet facing environment.

```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Elasticsearch and Kibana](06_ek_ssc.md)
