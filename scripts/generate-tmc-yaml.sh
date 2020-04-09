#!/bin/bash -e
: ${VMWARE_ID?"Need to set VMWARE_ID environment variable"}

# tkg-mgmt-acme-fitness.yaml
yq write -d0 tmc/config/namespace/tkg-mgmt-acme-fitness.yaml -i "fullName.clusterName" se-$VMWARE_ID-wlc-1
yq write -d0 tmc/config/namespace/tkg-mgmt-acme-fitness.yaml -i "objectMeta.labels.origin" $VMWARE_ID
yq write -d0 tmc/config/namespace/tkg-mgmt-acme-fitness.yaml -i "spec.workspaceName" $VMWARE_ID-acme-fitness-dev

# acme-fitness-dev.yaml
yq write -d0 tmc/config/workspace/acme-fitness-dev.yaml -i "fullName.name" $VMWARE_ID-acme-fitness-dev
yq write -d0 tmc/config/workspace/acme-fitness-dev.yaml -i "objectMeta.labels.origin" $VMWARE_ID
