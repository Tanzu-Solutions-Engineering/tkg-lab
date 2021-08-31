#!/bin/bash -ex

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh


export YTT_CONTROL_PLANE_ENDPOINT=$3
export YTT_VERSION=$4
export YTT_CLUSTER_NAME=$1
export CLUSTER=$1
export YTT_WORKER_REPLICAS=$2

export MGMT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
export PROVISIONER=$(yq e .tmc.provisioner $PARAMS_YAML)

export TMC_API_TOKEN=$(yq e .tmc.api-token $PARAMS_YAML)

mkdir -p generated/$CLUSTER
# cp config-templates/tmc-cluster-config-ytt.yaml generated/$CLUSTER/cluster-config.yaml

ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
ytt --data-values-env YTT --data-value-file SSH_KEY=./keys/${ENVIRONMENT_NAME}-ssh.pub -f ./config-templates/tmc-cluster-config-ytt.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER/cluster-config.yaml

tmc login --no-configure --name $(yq e .tmc.context-name $PARAMS_YAML)

tmc cluster create --file=generated/$CLUSTER/cluster-config.yaml 


currentstatus=$(tmc cluster get ${CLUSTER} -m ${MGMT_CLUSTER} -p ${PROVISIONER} -o json | jq -r '.status.phase')
statusdone="READY"
while [ "$currentstatus" != "$statusdone" ]
do
  echo "Still Building Cluster"
  sleep 20
  currentstatus=$(tmc cluster get ${CLUSTER} -m ${MGMT_CLUSTER} -p ${PROVISIONER} -o json | jq -r '.status.phase')
  echo "current status: ${currentstatus}"
done

echo "Cluster Build Complete"

echo "getting admin kubeconfig"
tmc cluster auth admin-kubeconfig get ${CLUSTER} -m ${MGMT_CLUSTER} -p ${PROVISIONER} > keys/${CLUSTER}.kubeconfig
echo "saved to keys/${CLUSTER}.kubeconfig"

echo "Setting policy for platform team"
$TKG_LAB_SCRIPTS/tmc-policy.sh \
  ${CLUSTER} \
  cluster.admin \
  platform-team



# # Retrive admin kubeconfig
# tanzu cluster kubeconfig get $CLUSTER --admin

# kubectl config use-context $CLUSTER-admin@$CLUSTER

# # Create namespace that the lab uses for kapp metadata
# kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml

# # TODO: This is a temporary fix until this is updated with the add-on.  Addresses noise logs in pinniped-concierge
# kubectl apply -f tkg-extensions-mods-examples/authentication/pinniped/pinniped-rbac-extension.yaml
