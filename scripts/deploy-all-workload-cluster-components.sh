#!/bin/bash -e

# Workload Step 1
./scripts/deploy-workload-cluster.sh \
  $(yq r params.yaml workload-cluster.name) \
  $(yq r params.yaml workload-cluster.worker-replicas)
# Workload Step 2
./scripts/tmc-attach.sh $(yq r params.yaml workload-cluster.name)
# Workload Step 3
./scripts/tmc-policy.sh \
  $(yq r params.yaml workload-cluster.name) \
  cluster.admin \
  platform-team
# Workload Step 4
IAAS=$(yq r params.yaml iaas)
if [ $IAAS = 'vsphere' ];
then
  ./scripts/deploy-metallb.sh \
          $(yq r params.yaml workload-cluster.name) \
          $(yq r params.yaml workload-cluster.metallb-start-ip) \
          $(yq r params.yaml workload-cluster.metallb-end-ip)
fi
./scripts/deploy-cert-manager.sh
./externalDNS/aws/deploy.sh $(yq r params.yaml workload-cluster.name)
./scripts/generate-and-apply-contour-yaml.sh $(yq r params.yaml workload-cluster.name) $(yq r params.yaml workload-cluster.ingress-fqdn)
#./scripts/update-dns-records-route53.sh $(yq r params.yaml workload-cluster.ingress-fqdn)
./scripts/generate-and-apply-cluster-issuer-yaml.sh $(yq r params.yaml workload-cluster.name)
# Workload Step 5
./scripts/generate-and-apply-gangway-yaml.sh \
   $(yq r params.yaml workload-cluster.name) \
   $(yq r params.yaml workload-cluster.gangway-fqdn)
./scripts/inject-dex-client.sh \
   $(yq r params.yaml management-cluster.name) \
   $(yq r params.yaml workload-cluster.name) \
   $(yq r params.yaml workload-cluster.gangway-fqdn)
# Workload Step 6
./scripts/generate-and-apply-fluent-bit-yaml.sh $(yq r params.yaml workload-cluster.name)
# Workload Step 7
./scripts/deploy-wavefront.sh $(yq r params.yaml workload-cluster.name)
# Workload Step 8
./scripts/velero.sh $(yq r params.yaml workload-cluster.name)
