# Install Kubeapps

## Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
kubeapps:
  server-fqdn: kubeapps.<workload-cluster domain name>
  oidc-issuer-fqdn: dex.<workload-cluster domain name>
```

## Prepare Okta for Kubeapps Client

1. Log into your Okta account you created as part of the [Okta Setup Lab](../mgmt-cluster/04_okta_mgmt.md).  The URL should be in your `params.yaml` file under okta.auth-server-fqdn.

2. Choose Applications (side menu) > Applications. Then click Create App Integration button. Then select OIDC - OpenID Connect radio option. For Application Type, choose Web Application radio button. Then click Next button.

3. Complete the form as follows, and then click Done.
  - Give your app a name: `Kubeapps`
  - For Grant type, check Authorization Code
  - Sign-in redirect URIs: `https://<kubeapps.oidc-issuer-fqdn from $PARAMS_YAML>/callback` 
```bash
echo "https://$(yq e .kubeapps.oidc-issuer-fqdn $PARAMS_YAML)/callback"
```
  - Sign-out redirect URIs: `https://<kubeapps.oidc-issuer-fqdn from $PARAMS_YAML>/logout`
```bash
echo "https://$(yq e .kubeapps.oidc-issuer-fqdn $PARAMS_YAML)/logout"
```

4. Capture `Client ID` and `Client Secret` for and put it in your $PARAMS_YAML file
```bash
okta:
  kubeapps-dex-app-client-id: <your kubeapps okta client id>
  kubeapps-dex-app-client-secret: <your kubeapps okta client secret>
```

5. Choose Sign On tab > Edit **OpenID Connect ID Token** section
  - Groups claim type => `Filter`
  - Groups claim filter => **groups** Matches regex **.\***

## Prepare Manifests and Deploy Dex

Due to the way okta provides thin-tokens, if we directly integrated kubeapps with okta, we would not recieve group membership.  Dex has the workflow to retrieve the group
membership and generate a new JWT token for kubeapps.  As such, we will deploy dex in the workload cluster to perform this mediation.

```bash
./dex/generate-and-apply-dex-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)
```

## Prepare Manifests and Deploy Kubeapps
Kubeapps should be installed in the workload cluster, as it is going to be available to all users. Prepare and deploy the YAML manifests for the related kubeapps K8S objects.  Manifest will be output into `generated/$CLUSTER_NAME/kubeapps/` in case you want to inspect.
```bash
./kubeapps/generate-and-apply-kubeapps-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)
```

## Validation Step
1. All kubeapps pods are in a running state:
```bash
kubectl get po -n kubeapps
```
2. Certificate is True and Ingress created:
```bash
kubectl get cert,ing -n kubeapps
```
3. Open a browser and navigate to https://<$KUBEAPPS_FQDN>.  
```bash
open https://$(yq e .kubeapps.server-fqdn $PARAMS_YAML)
```
4. Login as `alana`, who is an admin on the cluster.  You should be taken to the kubeapps home page
