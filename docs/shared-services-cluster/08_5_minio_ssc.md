# Install Minio

We will deploy Minio as a target for harbor images and Velero backups.

This is a minimalist and POC quality deployment of Minio.  This is not a component of Tanzu.  This deployment is just for the purpose of demonstration purpose.

## Set configuration parameters

The scripts to prepare the YAML to deploy minio depend on a parameters to be set.  Ensure the following are set in `params.yaml`:

```yaml
minio:
  server-fqdn: minio.dorn.tkg-aws-e2-lab.winterfell.live
  root-user: foo
  root-password: bar
  persistence-size: 40Gi
```

## Prepare Manifests and Deploy Minio

Minio images are pulled from Docker Hub.  Ensure your credentials are in the `params.yaml` file in order to avoid rate limit errors.

```yaml
dockerhub:
  username: REDACTED # Your dockerhub username
  password: REDACTED # Your dockerhub password
  email: REDACTED # Your dockerhub email
```

Prepare the YAML manifests for the related minio K8S objects.  Manifests will be output into `generated/$SHARED_SERVICES_CLUSTER_NAME/minio/` in case you want to inspect.

```bash
./scripts/generate-and-apply-minio-yaml.sh
```

## Validation Step

Visit minio UI and login with your credentials

```bash
open http://$(yq e .minio.server-fqdn $PARAMS_YAML):9000
```

## Go to Next Step

[Enable Data Protection and Setup Nightly Backup on Shared Services Cluster](09_velero_ssc.md)

