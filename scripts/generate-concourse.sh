#!/bin/bash -e

CLUSTER_NAME=$(yq r params.yaml shared-services-cluster.name)
CONCOURSE_URL=$(yq r params.yaml concourse.url)
CONCOURSE_NAMEPSACE=$(yq r params.yaml concourse.url)

mkdir -p generated/$CLUSTER_NAME/concourse/

cp concourse/concourse-values-contour-template.yaml generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml

if [ `uname -s` = 'Darwin' ]; 
then
  sed -i '' -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
else
  sed -i -e "s/CONCOURSE_URL/$CONCOURSE_URL/g" generated/$CLUSTER_NAME/concourse/concourse-values-contour.yaml
fi
