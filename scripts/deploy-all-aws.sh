#!/bin/bash -e

source ./scripts/set-env.sh

# Management Step 1
./scripts/01-prep-aws-objects.sh
./scripts/02-deploy-aws-mgmt-cluster.sh
./scripts/03-post-deploy-mgmt-cluster.sh
# Management Step 2
./scripts/tmc-attach.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 3
./scripts/create-hosted-zone.sh
./scripts/retrieve-lets-encrypt-ca-cert.sh
# Management Step 6
./scripts/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
./scripts/update-dns-records-route53.sh $(yq r $PARAMS_YAML management-cluster.ingress-fqdn)
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 7
./scripts/generate-and-apply-dex-yaml.sh
# Management Step 8
./scripts/deploy-wavefront.sh $(yq r $PARAMS_YAML management-cluster.name)

# Shared Services Step 1
./scripts/deploy-workload-cluster.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  $(yq r $PARAMS_YAML shared-services-cluster.worker-replicas)
# Shared Services Step 2
./scripts/tmc-attach.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 3
./scripts/tmc-policy.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  cluster.admin \
  platform-team
# Shared Services Step 4
./scripts/deploy-cert-manager.sh
./scripts/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
./scripts/update-dns-records-route53.sh $(yq r $PARAMS_YAML shared-services-cluster.ingress-fqdn)
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 5
./scripts/generate-and-apply-gangway-yaml.sh \
   $(yq r $PARAMS_YAML shared-services-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.gangway-fqdn)
./scripts/inject-dex-client.sh \
   $(yq r $PARAMS_YAML management-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.gangway-fqdn)
# Shared Services Step 6
./scripts/generate-and-apply-elasticsearch-kibana-yaml.sh
# Shared Services Step 7
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 8
./scripts/deploy-wavefront.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 9
./scripts/velero.sh $(yq r $PARAMS_YAML shared-services-cluster.name)

# Management Step 9
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 10
./scripts/velero.sh $(yq r $PARAMS_YAML management-cluster.name)

# Workload Step 1
./scripts/deploy-all-workload-cluster-components.sh
