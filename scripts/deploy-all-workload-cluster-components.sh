#!/bin/bash -e

source ./scripts/set-env.sh

# Workload Step 1
./scripts/deploy-workload-cluster.sh \
  $(yq r $PARAMS_YAML workload-cluster.name) \
  $(yq r $PARAMS_YAML workload-cluster.worker-replicas)
# Workload Step 2
./scripts/tmc-attach.sh $(yq r $PARAMS_YAML workload-cluster.name)
# Workload Step 3
./scripts/tmc-policy.sh \
  $(yq r $PARAMS_YAML workload-cluster.name) \
  cluster.admin \
  platform-team
# Workload Step 4
IAAS=$(yq r $PARAMS_YAML iaas)
if [ $IAAS = 'vsphere' ];
then
  ./scripts/deploy-metallb.sh \
          $(yq r $PARAMS_YAML workload-cluster.name) \
          $(yq r $PARAMS_YAML workload-cluster.metallb-start-ip) \
          $(yq r $PARAMS_YAML workload-cluster.metallb-end-ip)
fi
./scripts/deploy-cert-manager.sh
./scripts/generate-and-apply-contour-yaml.sh $(yq r $PARAMS_YAML workload-cluster.name)
./scripts/update-dns-records-route53.sh $(yq r $PARAMS_YAML workload-cluster.ingress-fqdn)
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r $PARAMS_YAML workload-cluster.name)
# Workload Step 5
./scripts/generate-and-apply-gangway-yaml.sh \
   $(yq r $PARAMS_YAML workload-cluster.name) \
   $(yq r $PARAMS_YAML workload-cluster.gangway-fqdn)
./scripts/inject-dex-client.sh \
   $(yq r $PARAMS_YAML management-cluster.name) \
   $(yq r $PARAMS_YAML workload-cluster.name) \
   $(yq r $PARAMS_YAML workload-cluster.gangway-fqdn)
# Workload Step 6
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r $PARAMS_YAML workload-cluster.name)
# Workload Step 7
./scripts/deploy-wavefront.sh $(yq r $PARAMS_YAML workload-cluster.name)
# Workload Step 8
./scripts/velero.sh $(yq r $PARAMS_YAML workload-cluster.name)
