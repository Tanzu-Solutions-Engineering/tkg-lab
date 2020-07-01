#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE svcCluster.name)
./extensions/install-external-dns.sh