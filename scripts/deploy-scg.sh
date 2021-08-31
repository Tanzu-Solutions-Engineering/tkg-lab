#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name"
  exit 1
fi

SCG_HOME=$TKG_LAB_SCRIPTS/../spring-cloud-gateway/scg

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME


PIVOTAL_REGISTRY_URL=$(yq e .pivnet.registry-url $PARAMS_YAML)
PIVOTAL_REGISTRY_USER=$(yq e .pivnet.username $PARAMS_YAML)
PIVOTAL_REGISTRY_PASSWORD=$(yq e .pivnet.password $PARAMS_YAML)

HARBOR_REGISTRY_URL=$(yq e .harbor.harbor-cn $PARAMS_YAML)
HARBOR_REGISTRY_USER=$(yq e .harbor.admin-user $PARAMS_YAML)
HARBOR_REGISTRY_PASSWORD=$(yq e .harbor.admin-password $PARAMS_YAML)

SCG_HARBOR_PROJECT_NAME=$(yq e .scg.harbor-project $PARAMS_YAML)
SCG_K8S_NS=$(yq e .scg.k8s-ns $PARAMS_YAML)

SCG_DOWNLOAD_COMMAND=$(yq e .scg.scg-download-command $PARAMS_YAML)
SCG_FILENAME=$(yq e .scg.filename $PARAMS_YAML)
PIVNET_API_TOKEN=$(yq e .pivnet.api-token $PARAMS_YAML)

pivnet login --api-token=${PIVNET_API_TOKEN}

# echo ${PIVOTAL_REGISTRY_PASSWORD} | docker login ${PIVOTAL_REGISTRY_URL} -u ${PIVOTAL_REGISTRY_USER} --password-stdin
echo ${HARBOR_REGISTRY_PASSWORD}  | docker login ${HARBOR_REGISTRY_URL}  -u ${HARBOR_REGISTRY_USER}  --password-stdin


mkdir -p $SCG_HOME  

if [[ ! -f "${SCG_HOME}/../${SCG_FILENAME}" ]]; then
  pushd $SCG_HOME/..
  bash -c "${SCG_DOWNLOAD_COMMAND}"
  popd
fi


tar xvfz ${SCG_HOME}/../${SCG_FILENAME} -C ${SCG_HOME} --strip-components=1

$TKG_LAB_SCRIPTS/create-harbor-scg-project.sh

$SCG_HOME/scripts/relocate-images.sh ${HARBOR_REGISTRY_URL}/${SCG_HARBOR_PROJECT_NAME}

kubectl create ns ${SCG_K8S_NS} --dry-run=client -oyaml | kubectl apply -f -

kubectl create secret docker-registry spring-cloud-gateway-image-pull-secret -n ${SCG_K8S_NS} \
  --docker-server=${HARBOR_REGISTRY_URL} \
  --docker-username=${HARBOR_REGISTRY_USER} \
  --docker-password=${HARBOR_REGISTRY_PASSWORD} --dry-run=client -oyaml | kubectl apply -f -

$SCG_HOME/scripts/install-spring-cloud-gateway.sh ${SCG_HOME}/$(yq e .scg.chart-tarball-path $PARAMS_YAML)  ${SCG_K8S_NS}

# kbld relocate -f $TBS_HOME/images.lock --lock-output $TBS_HOME/images-relocated.lock --repository ${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}

# ytt -f $TBS_HOME/values.yaml \
#     -f $TBS_HOME/manifests/ \
#     -v docker_repository="${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}" \
#     -v docker_username="${HARBOR_REGISTRY_USER}" \
#     -v docker_password="${HARBOR_REGISTRY_PASSWORD}" \
#     | kbld -f ${TBS_HOME}/images-relocated.lock -f- \
#     | kapp deploy -a tanzu-build-service -f- -y

# kp import -f $TBS_HOME/../$TBS_DESCRIPTOR_FILENAME

# export CLUSTER_BUILDER_REG_PATH=${HARBOR_REGISTRY_URL}/${TBS_HARBOR_PROJECT_NAME}/${TBS_HARBOR_REPO_NAME}/python-cluster-builder:0.0.1
# yq e -i '.spec.tag = env(CLUSTER_BUILDER_REG_PATH)' $TBS_HOME/../python-cluster-builder.yaml


# kubectl apply -f $TBS_HOME/../python-cluster-store.yaml
# kubectl apply -f $TBS_HOME/../python-cluster-builder.yaml