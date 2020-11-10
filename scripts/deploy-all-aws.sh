#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

# Management Step 1
$TKG_LAB_SCRIPTS/01-prep-aws-objects.sh
$TKG_LAB_SCRIPTS/02-deploy-aws-mgmt-cluster.sh
$TKG_LAB_SCRIPTS/03-post-deploy-mgmt-cluster.sh
# Management Step 2
$TKG_LAB_SCRIPTS/tmc-attach.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 3
$TKG_LAB_SCRIPTS/create-hosted-zone.sh
$TKG_LAB_SCRIPTS/retrieve-lets-encrypt-ca-cert.sh
# Management Step 6
$TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
$TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh \
  $(yq r $PARAMS_YAML management-cluster.name) \
  $(yq r $PARAMS_YAML management-cluster.ingress-fqdn)
$TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 7
$TKG_LAB_SCRIPTS/generate-and-apply-dex-yaml.sh
# Management Step 8
$TKG_LAB_SCRIPTS/deploy-wavefront.sh $(yq r $PARAMS_YAML management-cluster.name)

# Shared Services Step 1
$TKG_LAB_SCRIPTS/deploy-workload-cluster.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  $(yq r $PARAMS_YAML shared-services-cluster.worker-replicas)
# Shared Services Step 2
$TKG_LAB_SCRIPTS/tmc-attach.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 3
$TKG_LAB_SCRIPTS/tmc-policy.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  cluster.admin \
  platform-team
# Shared Services Step 4
$TKG_LAB_SCRIPTS/deploy-cert-manager.sh
$TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
$TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  $(yq r $PARAMS_YAML shared-services-cluster.ingress-fqdn)
$TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 5
$TKG_LAB_SCRIPTS/generate-and-apply-gangway-yaml.sh \
   $(yq r $PARAMS_YAML shared-services-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.gangway-fqdn)
$TKG_LAB_SCRIPTS/inject-dex-client.sh \
   $(yq r $PARAMS_YAML management-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.gangway-fqdn)
# Shared Services Step 6
$TKG_LAB_SCRIPTS/generate-and-apply-elasticsearch-kibana-yaml.sh
# Shared Services Step 7
$TKG_LAB_SCRIPTS/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 8
$TKG_LAB_SCRIPTS/deploy-wavefront.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 9
$TKG_LAB_SCRIPTS/dataprotection.sh $(yq r $PARAMS_YAML shared-services-cluster.name) \
 $(yq r $PARAMS_YAML shared-services-cluster.backup-location)

# Management Step 9
$TKG_LAB_SCRIPTS/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 10
$TKG_LAB_SCRIPTS/dataprotection.sh $(yq r $PARAMS_YAML management-cluster.name) \
  $(yq r $PARAMS_YAML management-cluster.backup-location)

# Workload Step 1
$TKG_LAB_SCRIPTS/deploy-all-workload-cluster-components.sh
