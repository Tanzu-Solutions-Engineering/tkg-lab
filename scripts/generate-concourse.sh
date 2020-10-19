#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
CONCOURSE_URL=$(yq r $PARAMS_YAML concourse.fqdn)

mkdir -p generated/$CLUSTER_NAME/concourse/

cp concourse/concourse-values-contour-template.yaml generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
else
  sed -i -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
fi
