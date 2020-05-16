#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE wlCluster.name)
export SECRET=$(yq r $PARAM_FILE wl.secret)
export GANGWAY_INGRESS=$(yq r $PARAM_FILE wl.gangway)

./extensions/install-gangway.sh