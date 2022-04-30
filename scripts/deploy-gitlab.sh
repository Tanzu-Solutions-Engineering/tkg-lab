#!/bin/bash -e

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

tmc login --no-configure --name $(yq e .tmc.context-name $PARAMS_YAML)

tmc workspace create -n $GITLAB_TMC_WORKSPACE -d "Workspace for Gitlab"
tmc cluster namespace create -c $CLUSTER_NAME -n $GITLAB_NAMESPACE -d "Gitlab product installation" -k $GITLAB_TMC_WORKSPACE -m ${MGMT_CLUSTER} -p ${PROVISIONER}

${TKG_LAB_SCRIPTS}/generate-gitlab.sh

kubectl config use-context ${CLUSTER_NAME}-admin@${CLUSTER_NAME}

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab -f generated/$CLUSTER_NAME/gitlab/values-gitlab.yaml -n $GITLAB_NAMESPACE
