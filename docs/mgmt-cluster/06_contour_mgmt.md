# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations and until AVI AKO is installed in the mgmt cluster!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:

```bash
./scripts/deploy-metallb.sh \
  $(yq e .management-cluster.name $PARAMS_YAML) \
  $(yq e .management-cluster.metallb-start-ip $PARAMS_YAML) \
  $(yq e .management-cluster.metallb-end-ip $PARAMS_YAML)
```

## Deploy Contour

Apply Contour configuration. We explicitly configure contour to use service type=LoadBalancer for Envoy.  Use this script to apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq e .management-cluster.name $PARAMS_YAML)
```

## Verify Contour

Once it is deployed, you can see all pods `Running` and the the Load Balancer up.  

```bash
kubectl get pod,svc -n tanzu-system-ingress
```

## Check out Cloud Load Balancer (for AWS and Azure)

The EXTERNAL IP for AWS will be set to the name of the newly configured AWS Elastic Load Balancer, which will also be visible in the AWS UI and CLI.

If using AWS:

```bash
aws elb describe-load-balancers
```

If Azure:

```bash
az network lb list
```

## Setup DNS for Wildcard Domain Contour Ingress

We will leverage [external-dns](https://github.com/kubernetes-sigs/external-dns) for kubernetes managed DNS updates using the [helm chart from Bitnami catalog](https://bitnami.com/stack/external-dns/helm)  Then by applying an annotation containing the wildcard domain for the ingress to the `envoy` service, `external-dns` will observe the change and make the desired updates within the DNS Provider: Route53 (default) or Google Cloud DNS depending on the configuration of `dns.provider`.  

If we are leveraging Route53, we require access to AWS.  See [external-dns docs](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md) for minimum access required for the AWS account you are using.  If necessary, set the policy an assign to the user for the access key.  So regardless of TKG IaaS, ensure the following are set in `params.yaml`:

```yaml
aws:
  region: your-region
  access-key-id: your-access-key-id
  secret-access-key: your-secret-access-key
```

If we are leveraging Google Cloud DNS, we require access to Google Cloud and permissions to manage DNS zones. The next script will leverage the `gcloud` CLI to create the required service-account and permissions, therefore your `gcloud` should have been initialized in the local configuration as detailed in the [DNS Certs Management](03_dns_certs_mgmt.md)
```yaml
gcloud:
  project: your-project-id
```

For any DNS provider, execute the script below to deploy `external-dns` and to apply the annotation.

```bash
./scripts/generate-and-apply-external-dns-yaml.sh \
  $(yq e .management-cluster.name $PARAMS_YAML) \
  $(yq e .management-cluster.ingress-fqdn $PARAMS_YAML)
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect. It is assumed that if you IaaS is AWS or Azure, then you will use the `http` challenge type and if your IaaS is vSphere, you will use the `dns` challenge type as a non-interfacing environment. If using the `dns` challenge, this script assumes Route 53 DNS by default unless `dns.provider` is set to `gcloud-dns`.

```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq e .management-cluster.name $PARAMS_YAML)
```

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Monitoring](07_update_pinniped_config_mgmt.md)
