#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

IAAS=$(yq r $PARAMS_YAML iaas)

# Management Step 1
# vSphere's prep script is not idempotent and can only be run once, so we assume it has already happened
if [ "$IAAS" != "vsphere" ];
then
  $TKG_LAB_SCRIPTS/01-prep-$IAAS-objects.sh
fi
# Intentionally skiping 01-prep-$IAAS-objects.sh as this was likely done manually
$TKG_LAB_SCRIPTS/02-deploy-$IAAS-mgmt-cluster.sh
$TKG_LAB_SCRIPTS/03-post-deploy-mgmt-cluster.sh
# Management Step 2
# TMC Attach NOOP
# Management Step 3
$TKG_LAB_SCRIPTS/create-dns-zone.sh
$TKG_LAB_SCRIPTS/retrieve-lets-encrypt-ca-cert.sh
# Management Step 6
if [ "$IAAS" = "vsphere" ];
then
  $TKG_LAB_SCRIPTS/deploy-metallb.sh \
    $(yq r $PARAMS_YAML management-cluster.name) \
    $(yq r $PARAMS_YAML management-cluster.metallb-start-ip) \
    $(yq r $PARAMS_YAML management-cluster.metallb-end-ip)
fi
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
  $(yq r $PARAMS_YAML shared-services-cluster.worker-replicas) \
  $(yq r $PARAMS_YAML shared-services-cluster.controlplane-endpoint)
# Shared Services Step 2
$TKG_LAB_SCRIPTS/tmc-attach.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 3
$TKG_LAB_SCRIPTS/tmc-policy.sh \
  $(yq r $PARAMS_YAML shared-services-cluster.name) \
  cluster.admin \
  platform-team
# Shared Services Step 4
if [ "$IAAS" = "vsphere" ];
then
  $TKG_LAB_SCRIPTS/deploy-metallb.sh \
    $(yq r $PARAMS_YAML shared-services-cluster.name) \
    $(yq r $PARAMS_YAML shared-services-cluster.metallb-start-ip) \
    $(yq r $PARAMS_YAML shared-services-cluster.metallb-end-ip)
fi
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
$TKG_LAB_SCRIPTS/dataprotection.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
# Shared Services Step 10
$TKG_LAB_SCRIPTS/generate-and-apply-harbor-yaml.sh \
   $(yq r $PARAMS_YAML management-cluster.name) \
   $(yq r $PARAMS_YAML shared-services-cluster.name)

# Management Step 9
$TKG_LAB_SCRIPTS/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML management-cluster.name)
# Management Step 10
$TKG_LAB_SCRIPTS/velero.sh $(yq r $PARAMS_YAML management-cluster.name)

# Workload Step 1
$TKG_LAB_SCRIPTS/deploy-all-workload-cluster-components.sh
