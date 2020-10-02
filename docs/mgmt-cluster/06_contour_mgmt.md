# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:

```bash
./scripts/deploy-metallb.sh \
        $(yq r $PARAMS_YAML management-cluster.name) \
        $(yq r $PARAMS_YAML management-cluster.metallb-start-ip) \
        $(yq r $PARAMS_YAML management-cluster.metallb-end-ip)
```

## Deploy Contour

Apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.  Use this script to apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
```

## Verify Contour

Once it is deployed, you can see all pods `Running` and the the Load Balancer up.  

```bash
kubectl get pod,svc -n tanzu-system-ingress
```

## Check out Cloud Load Balancer (AWS Only)

The EXTERNAL IP for AWS will be set to the name of the newly configured AWS Elastic Load Balancer, which will also be visible in the AWS UI and CLI:

```bash
aws elb describe-load-balancers
```

## Setup Route 53 DNS for Wildcard Domain Contour Ingress

We will leverage [external-dns](https://github.com/kubernetes-sigs/external-dns) for kubernetes managed DNS updates using the [helm chart from Bitnami catalog](https://bitnami.com/stack/external-dns/helm)  Then by applying an annotation containing the wildcard domain for the ingress to the `envoy` service, `external-dns` will observe the change and make the desired updates within Route53.  

As we are leveraging Route53, we require access to AWS.  See [external-dns docs](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md) for minimum access required for the AWS account you are using.  If necessary, set the policy an assign to the user for the access key.  So regardless of using vSphere or AWS as your TKG IaaS, ensure the following are set in `params.yaml`:

```yaml
aws:
  region: your-region
  access-key-id: your-access-key-id
  secret-access-key: your-secret-access-key
```

Execute the script below to deploy `external-dns` and to apply the annotation.

```bash
./scripts/generate-and-apply-external-dns-yaml.sh \
  $(yq r $PARAMS_YAML management-cluster.name) \
  $(yq r $PARAMS_YAML management-cluster.ingress-fqdn)
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect.
It is assumed that if you IaaS is AWS, then you will use the `http` challenge type and if your IaaS is vSphere, you will use the `dns` challenge type as a non-interfacing environment. If using the `dns` challenge, this script assumes Route 53 DNS.
```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
```

>Note: This script assumes AWS Route 53 configuration. If you decide to use Google Cloud DNS, please check [these Google Cloud DNS instructions](/docs/misc/goog_cloud_dns.md).

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Dex](07_dex_mgmt.md)
