#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE wlCluster.name)
./extensions/install-certmanager.sh