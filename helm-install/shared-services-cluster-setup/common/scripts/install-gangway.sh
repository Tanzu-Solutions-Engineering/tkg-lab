#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE svcCluster.name)
export SECRET=$(yq r $PARAM_FILE svcCluster.secret)
export GANGWAY_INGRESS=$(yq r $PARAM_FILE svcCluster.gangway)

./extensions/install-gangway.sh