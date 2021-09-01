#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

# export CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
# ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
# SSH_KEY_LOC=$(pwd)/keys/${ENVIRONMENT_NAME}-ssh
# export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(pwd)/keys/${ENVIRONMENT_NAME}-ssh"
# GITLAB_HOST=$(yq e .gitlab.web-domain $PARAMS_YAML)
# ACCELERATOR_URI="git@${GITLAB_HOST}:accelerators/"

# # git@gitlab.gitlab.ss.rhe2e.k10s.io:accelerators/cart.git

# FRONTEND_PROJECT=$(yq e .gitlab.frontend-project $PARAMS_YAML)
# IMAGECACHE_PROJECT=$(yq e .gitlab.imagecache-project $PARAMS_YAML)
# KNATIVE_SHIM_PROJECT=$(yq e .gitlab.knative-shim-project $PARAMS_YAML)
# CART_PROJECT=$(yq e .gitlab.cart-project $PARAMS_YAML)
# CATALOG_PROJECT=$(yq e .gitlab.catalog-project $PARAMS_YAML)
# ORDER_PROJECT=$(yq e .gitlab.order-project $PARAMS_YAML)
# PAYMENT_PROJECT=$(yq e .gitlab.payment-project $PARAMS_YAML)
# LOADGEN_PROJECT=$(yq e .gitlab.loadgen-project $PARAMS_YAML)

# kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

# for proj in ${FRONTEND_PROJECT} ${IMAGECACHE_PROJECT} ${KNATIVE_SHIM_PROJECT} ${CART_PROJECT} ${CATALOG_PROJECT} ${ORDER_PROJECT} ${PAYMENT_PROJECT} ${LOADGEN_PROJECT}
# do
#   pushd ${TKG_LAB_SCRIPTS}/../../acme-3.1/accelerators/${proj}
#     mv ./k8s/k8s-accelerator-deployment-tpl.yaml.hide ./k8s/k8s-accelerator-deployment-tpl.yaml
#     ytt -f ./k8s/k8s-accelerator-deployment-tpl.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > ./k8s/k8s-accelerator-deployment.yaml
#     mv ./k8s/k8s-accelerator-deployment-tpl.yaml ./k8s/k8s-accelerator-deployment-tpl.yaml.hide
#     git init --initial-branch=main
#     git add .
#     git commit -m 'init' || sleep 0
#     git remote add gl ${ACCELERATOR_URI}${proj}.git
#     git push -u gl main
#     kubectl apply -f ./k8s/k8s-accelerator-deployment.yaml
#   popd
# done

WORKDIR=${TKG_LAB_SCRIPTS}/../../workdir 
mkdir -p $WORKDIR
ACCEL_FQDN=$(yq e .app-accelerator.fqdn $PARAMS_YAML)
ACCEL_URL=https://${ACCEL_FQDN}/api/accelerators/zip?name=
APP_PARAMS_JSON=${TKG_LAB_SCRIPTS}/../../app-params.json

# curl -vv "https://app-accelerator.ss.rhe2e.k10s.io/api/accelerators/zip?name=catalog-accelerator" -X POST --data "@catalog-request.json" -o test.zip

for accel in shopping-cart-accelerator catalog-accelerator frontend-accelerator image-cache-accelerator knative-shim-accelerator loadgen-accelerator order-accelerator payment-accelerator
do
  options=$(cat ${APP_PARAMS_JSON} | jq .[\"${accel}\"])
  projName=$(echo ${options} | jq -r .options.projectName)
  curl -vv ${ACCEL_URL}${accel} -X POST --data "${options}" -o ${WORKDIR}/${projName}.zip
  unzip -o ${WORKDIR}/${projName}.zip -d ${WORKDIR}
done