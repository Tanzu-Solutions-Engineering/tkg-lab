#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE mgmtCluster.name)
export IAAS='vsphere'
./extensions/install-external-dns.sh