#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
GITLAB_HOST=$(yq e .gitlab.web-domain $PARAMS_YAML)
export APP_GROUP_NAME=$(yq e .gitlab.group-name $PARAMS_YAML)
APP_URI_PREFIX="https://${GITLAB_HOST}/${APP_GROUP_NAME}/"

HARBOR_ACME_PROJECT_NAME=$(yq e .acme-fitness.harbor-project $PARAMS_YAML )
HARBOR_FQDN=$(yq e .harbor.harbor-cn $PARAMS_YAML)

FRONTEND_PROJECT=$(yq e .gitlab.frontend-project $PARAMS_YAML)
IMAGECACHE_PROJECT=$(yq e .gitlab.imagecache-project $PARAMS_YAML)
KNATIVE_SHIM_PROJECT=$(yq e .gitlab.knative-shim-project $PARAMS_YAML)
CART_PROJECT=$(yq e .gitlab.cart-project $PARAMS_YAML)
CATALOG_PROJECT=$(yq e .gitlab.catalog-project $PARAMS_YAML)
ORDER_PROJECT=$(yq e .gitlab.order-project $PARAMS_YAML)
PAYMENT_PROJECT=$(yq e .gitlab.payment-project $PARAMS_YAML)
LOADGEN_PROJECT=$(yq e .gitlab.loadgen-project $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

for proj in ${FRONTEND_PROJECT} ${IMAGECACHE_PROJECT} ${KNATIVE_SHIM_PROJECT} ${CART_PROJECT} ${CATALOG_PROJECT} ${ORDER_PROJECT} ${PAYMENT_PROJECT} ${LOADGEN_PROJECT}
do
  pushd ${TKG_LAB_SCRIPTS}/../../workdir/${proj}
    
    DESTINATION_GIT=${APP_URI_PREFIX}${proj}
    IMAGE_REPO=${HARBOR_FQDN}/${HARBOR_ACME_PROJECT_NAME}/${proj}:0.0.1
    if [[ -f ./k8s/kp-image.yaml ]]; then
      ytt -f ./k8s/kp-image.yaml --data-value destinationGit=${DESTINATION_GIT} --data-value imageRepo=${IMAGE_REPO} --data-value projectName=${proj} \
        | kubectl apply -f-
    fi
    
  popd
done


for proj in ${FRONTEND_PROJECT} ${IMAGECACHE_PROJECT} ${KNATIVE_SHIM_PROJECT} ${CART_PROJECT} ${CATALOG_PROJECT} ${ORDER_PROJECT} ${PAYMENT_PROJECT} ${LOADGEN_PROJECT}
do
  pushd ${TKG_LAB_SCRIPTS}/../../workdir/${proj}
    if [[ -f ./k8s/kp-image.yaml ]]; then
      RESULT=$(kubectl get image -n acme-build ${proj} -o json | jq -r '.status.conditions[] | select(.type == "Ready").status')
      while [ $RESULT != "True" ]
      do 
        sleep 3
        RESULT=$(kubectl get image -n acme-build ${proj} -o json | jq -r '.status.conditions[] | select(.type == "Ready").status')
      done
    fi
  popd
done
