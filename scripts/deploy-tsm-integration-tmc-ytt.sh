#!/bin/bash -ex

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh


export YTT_CLUSTER_NAME=$1
export CLUSTER=$1
# export YTT_INTEGRATION_NAME=${YTT_CLUSTER_NAME}-TSM

export MGMT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
export PROVISIONER=$(yq e .tmc.provisioner $PARAMS_YAML)

export TMC_API_TOKEN=$(yq e .tmc.api-token $PARAMS_YAML)

# mkdir -p generated/$CLUSTER
# cp config-templates/tmc-cluster-config-ytt.yaml generated/$CLUSTER/cluster-config.yaml

ENVIRONMENT_NAME=$(yq e .environment-name $PARAMS_YAML)
ytt --data-values-env YTT  -f ./config-templates/tsm-integration.yaml -f ${PARAMS_YAML} --ignore-unknown-comments > generated/$CLUSTER/tsm-integration.yaml

tmc login --no-configure --name $(yq e .tmc.context-name $PARAMS_YAML)

tmc cluster integration create --file=generated/$CLUSTER/tsm-integration.yaml 


# currentstatus=$(tmc cluster get ${CLUSTER} -m ${MGMT_CLUSTER} -p ${PROVISIONER} -o json | jq -r '.status.phase')
# statusdone="READY"
# while [ "$currentstatus" != "$statusdone" ]
# do
#   echo "Still Building Cluster"
#   sleep 20
#   currentstatus=$(tmc cluster get ${CLUSTER} -m ${MGMT_CLUSTER} -p ${PROVISIONER} -o json | jq -r '.status.phase')
#   echo "current status: ${currentstatus}"
# done

echo "Integration complete"
