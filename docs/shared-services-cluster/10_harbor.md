# Install Harbor Image Registry

## Set environment variables
The following section should be added to or exist in your local params.yaml file:

```yaml
harbor:
  admin-password: FOO
  harbor-cn: harbor.<shared-cluster domain name>
```
> NOTE: Since TKG 1.3 the Notary FQDN is forced to be "notary."+harbor-cn

### S3 Backing for Harbor
The default settings for Harbor use PVCs behind the registry pods for blob storage.  Persistent Volume performance can be slow in home labs, or environments with poor storage or networking performance.  You can opt in to using S3 compatible storage as the backing for Harbor, and this can dramatically increase the performance in these environments.

To use S3 blob storage for images managed by Harbor, you can use the following settings in your params.yaml file:
> NOTE: There is a known problem with the first TKG 1.4 that prevents this from working fine when S3 storage is configured. This will be updated as soon as there is a fix.
```yaml
harbor:
  admin-password: FOO
  harbor-cn: harbor.<shared-cluster domain name>
  blob-storage:
    type: s3 # Default is PVC, and can optionally be S3/MinIO
    region: us-east-1
    regionendpoint: http://freenas.home:9000 # Not needed for AWS S3
    access-key-id: minio
    secret-access-key: minio1234
    bucket: harbor-storage
    secure: false # set to true for HTTPS endpoints/AWS S3
```

Since this storage is external to the process, you will need to clean it up if you decide to tear down your environment.

## Prepare Manifests and Deploy Harbor Package
Harbor Registry will be installed in the shared services cluster, as it is going to be available to all users.  Prepare and deploy the YAML manifests for the related Harbor K8S objects.  Manifest will be output into `generated/$SHAREDSVC_CLUSTER_NAME/harbor` in case you want to inspect.

```bash
./scripts/generate-and-apply-harbor-yaml.sh \
   $(yq e .management-cluster.name $PARAMS_YAML) \
   $(yq e .shared-services-cluster.name $PARAMS_YAML)
```

The scripts will first create the Harbor certificates and check they are valid, which depends on the Let's Encrypt / Acme challenge to be resolved, that can take a couple of minutes.


## Final validation Step
1. All harbor pods are in a running state:
```bash
kubectl get po -n tanzu-system-registry
```

2. Open a browser and navigate to https://<$HARBOR_CN>.  The default user is admin and pwd is Harbor12345
```bash
open https://$(yq e .harbor.harbor-cn $PARAMS_YAML)
```


## Add Integration with Okta

### Add an additional application to your Okta Account

1. Log into your Okta account you created as part of the [Okta Setup Lab](../mgmt-cluster/04_okta_mgmt.md).  The URL should be in your `params.yaml` file under okta.auth-server-fqdn.

2. Choose Applications (side menu) > Application.   Then click `Create App Integration` button.  Then select `OIDC - OpenID Connect` radio option. For Application Type, choose `Web Application` radio button.  Then click `Next` button.

3. Complete the form as follows, and then click Done.
  - Give your app a name: `Harbor`
  - For Grant type, check Authorization Code and Refresh Token
  - Sign-in redirect URIs: `https://<harbor.harbor-cn from $PARAMS_YAML>/c/oidc/callback`
```bash
echo "https://$(yq e .harbor.harbor-cn $PARAMS_YAML)/c/oidc/callback"
```
  - Sign-out redirect URIs: `https://<harbor.harbor-cn from $PARAMS_YAML>/c/oidc/logout`
```bash
echo "https://$(yq e .harbor.harbor-cn $PARAMS_YAML)/c/oidc/logout"
```

3. Capture `Client ID` and `Client Secret` for and put it in your $PARAMS_YAML file.

```yaml
okta:
  harbor-app-client-id: MY_CLIENT_ID
  harbor-app-client-secret: MY_CLIENT_SECRET
```

4. Choose Sign On tab > Edit **OpenID Connect ID Token** section
  - Groups claim type => `Filter`
  - Groups claim filter => **groups** Matches regex **.\***

### Configure Harbor for OIDC Authentication

![Harbor OIDC Configuration](harbor-oidc-config.png)

1. Log-in to Harbor as admin and your configured admin password

2. On the left hand nav, select Administration -> Configuration

3. Choose Authentication tab, and then complete the form as follows:
  - Auth Mode: `OIDC`
  - OIDC Provider Name: `Okta`
  - OIDC Endpoint: `https://<okta.auth-server-fqdn from $PARAMS_YAML>/oauth2/default`
```bash
echo "https://$(yq e .okta.auth-server-fqdn $PARAMS_YAML)/oauth2/default"
```
  - OIDC Client ID: <okta.harbor-app-client-id from $PARAMS_YAML>
```bash
echo "$(yq e .okta.harbor-app-client-id $PARAMS_YAML)"
```
  - OIDC Client Secret: <okta.harbor-app-client-secret from $PARAMS_YAML>
```bash
echo "$(yq e .okta.harbor-app-client-secret $PARAMS_YAML)"
```
  - Group Claim Name: `groups`
  - OIDC Scope: `openid,profile,email,groups,offline_access`
  - Verify Certificate: `checked`

4. Click `Test OIDC Server`, then click `Save`

### Login to Harbor UI via OIDC

1. Logout of Harbor

2. In an incognito window, access Harbor UI: https://<harbor.harbor-cn from $PARAMS_YAML>.  You will now see a `Login Via OIDC Provider` button on the login page.

```bash
open https://$(yq e .harbor.harbor-cn $PARAMS_YAML)
```

3. Click `Login Via OIDC Provider` button, you will be redirected to Okta login page.

4. Login as `alana`, you will be redirected back to Harbor.  But this time it will ask you to provide a local harbor username to associate with your Okta profile.

5. You are now logged in with standard user privileges.

### Login to Harbor via docker cli

1. On top right of the page, click on your name, and select `User Profile`.  The resulting window contains your `CLI secret`.  This is the secret you must use to login to harbor using the docker cli.

2. Now login with docker cli.  Use your Okta username and your `CLI secret` from Harbor

```bash
docker login https://$(yq e .harbor.harbor-cn $PARAMS_YAML) -u alana
```

### Add Alana as Admin

1. Now logout of Harbor UI.  Log back in as `admin` and password `Harbor12345`

2. On the left hand nav, select Administration -> Users

3. Select `alana` user and click the `Set as Admin` button

4. Next time `alana` logs in, she will have admin privileges.

## Go to Next Step

At this point the shared services cluster is complete.  Go back and complete the management cluster setup tasks.

[Install FluentBit on Management Cluster](../mgmt-cluster/09_fluentbit_mgmt.md)
