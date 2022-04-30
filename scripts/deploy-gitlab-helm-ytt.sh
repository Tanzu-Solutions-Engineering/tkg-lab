#!/usr/bin/env bash

set -eux

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

export TMC_CLUSTER_GROUP=$(yq e .tmc.cluster-group $PARAMS_YAML)
export GITLAB_NAMESPACE=$(yq e .gitlab.namespace $PARAMS_YAML)
export GITLAB_TMC_WORKSPACE=$TMC_CLUSTER_GROUP-$(yq e .gitlab.tmc-workspace $PARAMS_YAML)
export CLUSTER_NAME=$(yq e .shared-services-cluster.name $PARAMS_YAML)
export IAAS=$(yq e .iaas $PARAMS_YAML)
export VMWARE_ID=$(yq e .vmware-id $PARAMS_YAML)

export MGMT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
export PROVISIONER=$(yq e .tmc.provisioner $PARAMS_YAML)

export TMC_API_TOKEN=$(yq e .tmc.api-token $PARAMS_YAML)

export GITLAB_ROOT_API_TOKEN=$(yq e .gitlab.root-api-token $PARAMS_YAML)
export GITLAB_ADMIN_API_TOKEN=$(yq e .gitlab.admin-api-token $PARAMS_YAML)
export GITLAB_ADMIN_PASSWORD=$(yq e .gitlab.admin-password $PARAMS_YAML)
export GITLAB_WEB_DOMAIN=$(yq e .gitlab.web-domain $PARAMS_YAML)
export GITLAB_GROUP_NAME=$(yq e .gitlab.group-name $PARAMS_YAML)
ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)



mkdir -p generated/$CLUSTER_NAME/gitlab

ytt -f ./config-templates/gitlab-certs-ytt.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER_NAME/gitlab/gitlab-certs-ytt.yaml
ytt -f ./config-templates/gitlab-stripped-down-ytt.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER_NAME/gitlab/gitlab-stripped-down-ytt.yaml

kubectl config use-context ${CLUSTER_NAME}-admin@${CLUSTER_NAME}
kubectl apply -f generated/$CLUSTER_NAME/gitlab/gitlab-certs-ytt.yaml -n ${GITLAB_NAMESPACE}

helm upgrade --install  gitlab gitlab/gitlab \
  --values generated/$CLUSTER_NAME/gitlab/gitlab-stripped-down-ytt.yaml \
  --namespace ${GITLAB_NAMESPACE}

GITLAB_ROOT_PW=$(kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' -n ${GITLAB_NAMESPACE} | base64 --decode ; echo)

echo "root-password: ${GITLAB_ROOT_PW}\n" > generated/${CLUSTER_NAME}/gitlab/instance-values.yaml


#wait for task-runner and webservice pods to come up
while [[ $(kubectl get pods -n ${GITLAB_NAMESPACE} -l app=task-runner -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for task-runner" && sleep 10; done
while [[ $(kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for webservice" && sleep 10; done



#@TODO: make idempotent

#create a root api token
kubectl exec  -n ${GITLAB_NAMESPACE} $(kubectl get pod -n ${GITLAB_NAMESPACE} -l "app=task-runner" \
  -o jsonpath='{.items[0].metadata.name}') \
  -- /usr/local/bin/gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Root API Token'); \
      token.set_token('${GITLAB_ROOT_API_TOKEN}'); token.save!"

curl https://${GITLAB_WEB_DOMAIN}/api/v4/users -X POST -H "Authorization: Bearer ${GITLAB_ROOT_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"admin\": \"true\", \"email\": \"gitlabadmin@test.com\", \"username\": \"gitlabadmin\", \"password\": \"${GITLAB_ADMIN_PASSWORD}\", \"name\": \"Gitlab Admin\", \"skip_confirmation\": \"true\" }"

kubectl exec  -n ${GITLAB_NAMESPACE} $(kubectl get pod -n ${GITLAB_NAMESPACE} -l "app=task-runner" \
  -o jsonpath='{.items[0].metadata.name}') \
  -- /usr/local/bin/gitlab-rails runner "token = User.find_by_username('gitlabadmin').personal_access_tokens.create(scopes: [:api], name: 'Gitlab Admin API Token'); \
      token.set_token('${GITLAB_ADMIN_API_TOKEN}'); token.save!"

curl https://${GITLAB_WEB_DOMAIN}/api/v4/user/keys -X POST -H "Authorization: Bearer ${GITLAB_ADMIN_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"title\": \"global-git-ssh\", \"key\": \"$(cat keys/${ENVIRONMENT_NAME}-ssh.pub)\" }"


GROUP_DETAILS=$(curl https://${GITLAB_WEB_DOMAIN}/api/v4/groups -X POST -H "Authorization: Bearer ${GITLAB_ADMIN_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"name\": \"${GITLAB_GROUP_NAME}\", \"path\": \"${GITLAB_GROUP_NAME}\", \"visibility\": \"public\"}")

GROUP_NS_ID=$(echo ${GROUP_DETAILS} | jq .id)
echo "group-ns-id: ${GROUP_NS_ID}\n" >> generated/${CLUSTER_NAME}/gitlab/instance-values.yaml


ACCEL_DETAILS=$(curl https://${GITLAB_WEB_DOMAIN}/api/v4/groups -X POST -H "Authorization: Bearer ${GITLAB_ADMIN_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"name\": \"accelerators\", \"path\": \"accelerators\", \"visibility\": \"public\"}")

ACCEL_NS_ID=$(echo ${ACCEL_DETAILS} | jq .id)
echo "accelerators-ns-id: ${ACCEL_NS_ID}\n" >> generated/${CLUSTER_NAME}/gitlab/instance-values.yaml





FRONTEND_PROJECT=$(yq e .gitlab.frontend-project $PARAMS_YAML)
IMAGECACHE_PROJECT=$(yq e .gitlab.imagecache-project $PARAMS_YAML)
KNATIVE_SHIM_PROJECT=$(yq e .gitlab.knative-shim-project $PARAMS_YAML)
CART_PROJECT=$(yq e .gitlab.cart-project $PARAMS_YAML)
CATALOG_PROJECT=$(yq e .gitlab.catalog-project $PARAMS_YAML)
ORDER_PROJECT=$(yq e .gitlab.order-project $PARAMS_YAML)
PAYMENT_PROJECT=$(yq e .gitlab.payment-project $PARAMS_YAML)
LOADGEN_PROJECT=$(yq e .gitlab.loadgen-project $PARAMS_YAML)

for proj in ${FRONTEND_PROJECT} ${IMAGECACHE_PROJECT} ${KNATIVE_SHIM_PROJECT} ${CART_PROJECT} ${CATALOG_PROJECT} ${ORDER_PROJECT} ${PAYMENT_PROJECT} ${LOADGEN_PROJECT}
do
  curl https://${GITLAB_WEB_DOMAIN}/api/v4/projects -X POST -H "Authorization: Bearer ${GITLAB_ADMIN_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"name\": \"${proj}\", \"visibility\": \"public\", \"namespace_id\": \"${GROUP_NS_ID}\"}"
done


for proj in ${FRONTEND_PROJECT} ${IMAGECACHE_PROJECT} ${KNATIVE_SHIM_PROJECT} ${CART_PROJECT} ${CATALOG_PROJECT} ${ORDER_PROJECT} ${PAYMENT_PROJECT} ${LOADGEN_PROJECT}
do
  curl https://${GITLAB_WEB_DOMAIN}/api/v4/projects -X POST -H "Authorization: Bearer ${GITLAB_ADMIN_API_TOKEN}" -H "Content-Type: application/json" \
  -d "{\"name\": \"${proj}\", \"visibility\": \"public\", \"namespace_id\": \"${ACCEL_NS_ID}\"}"
done

