# Install Contour on management cluster

## Deploy MetalLB (only for vSphere installations!!)
Secure a routable range of IPs to be the VIP/Float pool for LoadBalancers.
Run the script passing the range as parameters. Example:

```bash
./scripts/deploy-metallb.sh \
        $(yq r params.yaml management-cluster.name) \
        $(yq r params.yaml management-cluster.metallb-start-ip) \
        $(yq r params.yaml management-cluster.metallb-end-ip)
```

## Deploy Contour

Apply Contour configuration. We will use AWS one for any environment (including vSphere) since the only difference is the service type=LoadBalancer for Envoy which we need.  Use the script to update the contour configmap to enable `leaderelection` and apply yamls.
```bash
./scripts/generate-and-apply-contour-yaml.sh $(yq r params.yaml management-cluster.name)
```

## Verify Contour

Once it is deployed, wait until you can see all pods `Running` and the the Load Balancer up.  

```bash
kubectl get pod,svc -n tanzu-system-ingress
```

## Check out Cloud Load Balancer (AWS Only)

The EXTERNAL IP for AWS will be set to the name of the newly configured AWS Elastic Load Balancer, which will also be visible in the AWS UI and CLI:

```bash
aws elb describe-load-balancers
```

## Setup Route 53 DNS for Contour Ingress

Need to get the load balancer external IP for the envoy service and update AWS Route 53.  Execute the script below to do it automatically.

```bash
./scripts/update-dns-records-aws.sh $(yq r params.yaml management-cluster.ingress-fqdn)
```

## Prepare and Apply Cluster Issuer Manifests

Prepare the YAML manifests for the contour cluster issuer.  Manifest will be output into `clusters/mgmt/tkg-extensions-mods/ingress/contour/generated/` in case you want to inspect.
It is assumed that if you IaaS is AWS, then you will use the `http` challenge type and if your IaaS is vSphere, you will use the `dns` challenge type as a non-interfacing environment. If using the `dns` challenge, this script assumes Route 53 DNS.
```bash
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r params.yaml management-cluster.name)
```

>Note: This script assumes AWS Route 53 configuration. If not using Route 53 then tweak `generate-and-apply-cluster-issuer-yaml.sh` script for the right DNS challenge.

## Verify Cluster Issuer

Check to see that the ClusterIssuer is valid:

```bash
kubectl get clusterissuer letsencrypt-contour-cluster-issuer -o yaml
```

Look for the status to be Ready: True

## Go to Next Step

[Install Dex](07_dex_mgmt.md)
