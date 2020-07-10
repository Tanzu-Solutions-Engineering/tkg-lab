# Install Contour on Shared Services Cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:

```bash
./scripts/deploy-metallb.sh \
        $(yq r $PARAMS_YAML shared-services-cluster.name) \
        $(yq r $PARAMS_YAML shared-services-cluster.metallb-start-ip) \
        $(yq r $PARAMS_YAML shared-services-cluster.metallb-end-ip)
```

## Deploy Cert Manager

Our solution leverages cert manager to generate valid ssl certs.  Use this script to deploy cert manager into the cluster using TKG Extensions.

```bash
./scripts/deploy-cert-manager.sh
```

## Deploy Contour

Apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.  Use the script to update the contour configmap to enable `leaderelection` and apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

## Verify Contour

Once it is deployed, wait until you can see all pods `Running` and the the Load Balancer up.  

```bash
kubectl get pod,svc -n tanzu-system-ingress
```

## Setup Route 53 DNS for Contour Ingress

Need to get the load balancer external IP for the envoy service and update AWS Route 53.  Execute the script below to do it automatically.

```bash
./scripts/update-dns-records-route53.sh $(yq r $PARAMS_YAML shared-services-cluster.ingress-fqdn)
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect.
It is assumed that if you IaaS is AWS, then you will use the `http` challenge type and if your IaaS is vSphere, you will use the `dns` challenge type as a non-interfacing environment..
```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

>Note: This script assumes AWS Route 53 configuration. If you decide to use Google Cloud DNS, please check [these Google Cloud DNS instructions](../misc/google_cloud_dns.md).

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Gangway](05_gangway_ssc.md)
