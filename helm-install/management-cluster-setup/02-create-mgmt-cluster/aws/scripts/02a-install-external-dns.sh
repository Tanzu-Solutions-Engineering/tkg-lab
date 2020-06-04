#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE mgmtCluster.name)
./extensions/install-external-dns.sh