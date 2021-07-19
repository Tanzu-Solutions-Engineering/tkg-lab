# Update Pinniped Config

The default deployment approach is to leverage IP addresses and self signed certificates for the Pinniped supervisor endpoint.  However, in our lab we will leverage FQDN's managed by your DNS provider and Let's Encrypt to generate valid SSL certificates.  The `pinniped-addon` secret within the management cluster contains configuration information that drives this behavior.  In addition, there is some patching that is required of key Pinniped resources.

## Run Configuration Update Script

```bash
./scripts/update-pinniped-configuration.sh
```

## Verify Configuration

There are several key resources that contain the pinniped configuration state.  Let's get these resources to verify the specifications are as we expect.

```bash
kubectl get cm pinniped-info -n kube-public -oyaml
kubectl get federationdomain -n pinniped-supervisor -oyaml
kubectl get jwtauthenticator -n pinniped-concierge -oyaml
kubectl get oidcidentityprovider -n pinniped-supervisor -oyaml
```


## Go to Next Step

[Add Prometheus and Grafana to Management Cluster](08_monitoring_mgmt.md)
