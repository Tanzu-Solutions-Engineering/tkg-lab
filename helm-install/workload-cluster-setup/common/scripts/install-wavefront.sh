#!/bin/bash

export CLUSTER_NAME=$(yq r $PARAM_FILE wlCluster.name)
./extensions/install_wavefront.sh