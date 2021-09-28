#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply namespace as args"
  exit 1
fi

NAMESPACE=$1
DOCKER_HUB_USER=$(yq e .dockerhub.username $PARAMS_YAML)
DOCKER_HUB_PASSWORD=$(yq e .dockerhub.password $PARAMS_YAML)
DOCKER_HUB_EMAIL=$(yq e .dockerhub.email $PARAMS_YAML)

if [ "$DOCKER_HUB_USER" == null ] || [ "$DOCKER_HUB_USER" = "REDACTED" ] || \
  [ "$DOCKER_HUB_PASSWORD" == null ] || [ "$DOCKER_HUB_PASSWORD" = "REDACTED" ] || \
  [ "$DOCKER_HUB_EMAIL" == null ] || [ "$DOCKER_HUB_EMAIL" = "REDACTED" ]; then
  echo "Failed.  Must set dockerhub settings in param file"
  exit 1
fi

kubectl create secret docker-registry docker-hub-creds \
--docker-server=docker.io \
--docker-username=$DOCKER_HUB_USER \
--docker-password=$DOCKER_HUB_PASSWORD \
--docker-email=$DOCKER_HUB_EMAIL \
--namespace=$NAMESPACE \
--dry-run=client --output yaml | kubectl apply -f -

kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "docker-hub-creds"}]}' --namespace=$NAMESPACE
