#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name"
  exit 1
fi

TBS_HOME=$TKG_LAB_SCRIPTS/../tbs/build-service

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME


PIVOTAL_REGISTRY_URL=$(yq e .pivnet.registry-url $PARAMS_YAML)
PIVOTAL_REGISTRY_USER=$(yq e .pivnet.username $PARAMS_YAML)
PIVOTAL_REGISTRY_PASSWORD=$(yq e .pivnet.password $PARAMS_YAML)

HARBOR_REGISTRY_URL=$(yq e .harbor.harbor-cn $PARAMS_YAML)
HARBOR_REGISTRY_USER=$(yq e .harbor.admin-user $PARAMS_YAML)
HARBOR_REGISTRY_PASSWORD=$(yq e .harbor.admin-password $PARAMS_YAML)

TBS_HARBOR_PROJECT_NAME=$(yq e .tbs.harbor-project $PARAMS_YAML)
TBS_HARBOR_REPO_NAME=$(yq e .tbs.harbor-repo $PARAMS_YAML)
TBS_PRODUCT_VERSION=$(yq e .tbs.product-version $PARAMS_YAML)

# TBS_DOWNLOAD_COMMAND=$(yq e .tbs.tbs-download-command $PARAMS_YAML)
# TBS_DESCRIPTOR_DOWNLOAD_COMMAND=$(yq e .tbs.tbs-descriptor-download-command $PARAMS_YAML)
# TBS_FILENAME=$(yq e .tbs.filename $PARAMS_YAML)
# TBS_DESCRIPTOR_FILENAME=$(yq e .tbs.descriptor-filename $PARAMS_YAML)
# PIVNET_API_TOKEN=$(yq e .pivnet.api-token $PARAMS_YAML)

# pivnet login --api-token=${PIVNET_API_TOKEN}

echo ${PIVOTAL_REGISTRY_PASSWORD} | docker login ${PIVOTAL_REGISTRY_URL} -u ${PIVOTAL_REGISTRY_USER} --password-stdin
echo ${HARBOR_REGISTRY_PASSWORD}  | docker login ${HARBOR_REGISTRY_URL}  -u ${HARBOR_REGISTRY_USER}  --password-stdin


# mkdir -p $TBS_HOME  

# pushd $TBS_HOME/..
# bash -c "${TBS_DOWNLOAD_COMMAND}"
# bash -c "${TBS_DESCRIPTOR_DOWNLOAD_COMMAND}"
# popd

# tar xvf $TBS_HOME/../$TBS_FILENAME -C $TBS_HOME

$TKG_LAB_SCRIPTS/create-harbor-tbs-project.sh


imgpkg copy -b "registry.pivotal.io/build-service/bundle:${TBS_PRODUCT_VERSION}" --to-repo ${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}

imgpkg pull -b "${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}:${TBS_PRODUCT_VERSION}" -o /tmp/bundle

ytt -f /tmp/bundle/values.yaml \
    -f /tmp/bundle/config/ \
    -v docker_repository="${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}" \
    -v docker_username="${HARBOR_REGISTRY_USER}" \
    -v docker_password="${HARBOR_REGISTRY_PASSWORD}" \
    -v tanzunet_username="${PIVOTAL_REGISTRY_USER}" \
    -v tanzunet_password="${PIVOTAL_REGISTRY_PASSWORD}" \
    | kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
    | kapp deploy -a tanzu-build-service -f- -y


sleep 30
kubectl -n build-service get TanzuNetDependencyUpdater dependency-updater -o yaml





# kbld relocate -f $TBS_HOME/images.lock --lock-output $TBS_HOME/images-relocated.lock --repository ${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}

#ytt -f $TBS_HOME/values.yaml \
#    -f $TBS_HOME/manifests/ \
#    -v docker_repository="${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}" \
#    -v docker_username="${HARBOR_REGISTRY_USER}" \
#    -v docker_password="${HARBOR_REGISTRY_PASSWORD}" \
#    | kbld -f ${TBS_HOME}/images-relocated.lock -f- \
#    | kapp deploy -a tanzu-build-service -f- -y

# kp import -f $TBS_HOME/../$TBS_DESCRIPTOR_FILENAME

# export CLUSTER_BUILDER_REG_PATH=${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}/python-cluster-builder:0.0.1
# yq e -i '.spec.tag = env(CLUSTER_BUILDER_REG_PATH)' $TBS_HOME/../python-cluster-builder.yaml


# kubectl apply -f $TBS_HOME/../python-cluster-store.yaml
# kubectl apply -f $TBS_HOME/../python-cluster-builder.yaml



