#!/usr/bin/env bash

set -x
set -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/../scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply 1 arg"
  exit 1
fi

export VMW_CLOUD_API_TOKEN=$(yq e .tmc.api-token $PARAMS_YAML)
export CLUSTER_NAME=$1
export TSM_HOST=$(yq e .tsm.host $PARAMS_YAML)
export ACME_NAMESPACE=$(yq e .tsm.gns-ns $PARAMS_YAML)
export GNS_NAME=$(yq e .tsm.gns-name $PARAMS_YAML)
export GNS_DOMAIN=$(yq e .tsm.gns-domain $PARAMS_YAML)

echo "Exchanging API token for access token"

AT=$(curl -s 'https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize' \
            -H 'authority: console.cloud.vmware.com' \
            -H 'pragma: no-cache' \
            -H 'cache-control: no-cache' \
            -H 'accept: application/json, text/plain, */*' \
            --data-raw "refresh_token=${VMW_CLOUD_API_TOKEN}" --compressed | jq -r '.access_token')

# https://prod-2.nsxservicemesh.vmware.com/tsm/v1alpha1/clusters/robtest-9wwdn
# echo "Creating unique TSM token for cluster"
# TSM_TOKEN=$(curl -X PUT "https://${TSM_HOST}/tsm/v1alpha1/clusters/${CLUSTER_ID}" \
# -H "Accept: application/json, text/plain, */*" \
# -H "Accept-Encoding: gzip, deflate, br" \
# -H "Accept-Language: en-US,en;q=0.9"  \
# -H "csp-auth-token: $AT" \
# -H "Content-Type: application/json" \
# --data-binary "{\"displayName\":\"${CLUSTER_ID}\",\"description\":\"Auto-Created by tkg-lab\",\"tags\":[\"owner: ${VMWARE_ID}\"],\"labels\":[],\"namespaceExclusions\":[{\"match\":\"cert-manager\",\"type\":\"EXACT\"}],\"autoInstallServiceMesh\":true,\"enableNamespaceExclusions\":true}" \
# --compressed | jq -r '.token')

# # [{\"match\":\"tanzu-system-\",\"type\":\"START_WITH\"}]

# #maybe this helps with the ValidationFailed race condition??
# sleep 5

# echo "applying the operator"
# kubectl apply -f https://${TSM_HOST}/cluster-registration/k8s/operator-deployment.yaml

# echo "creating the secret for the TSM token"
# kubectl -n vmware-system-tsm create secret generic cluster-token --from-literal=token=$TSM_TOKEN


# state="INIT"

# until [[ $state == "Ready" ]]
# do 
#     echo "State = ${state}, waiting..."
#     sleep 15
#     state=$(curl -X GET "https://${TSM_HOST}/tsm/v1alpha1/clusters/${CLUSTER_ID}" \
#     -H "Accept: application/json, text/plain, */*" \
#     -H "Accept-Language: en-US,en;q=0.9"  \
#     -H "csp-auth-token: $AT" | jq -r '.status.state')
# done


# state="INIT"


# until [[ $state == "Healthy" ]]
# do 
#     echo "State = ${state}, waiting..."
#     sleep 15
#     state=$(curl -s -X GET "https://${TSM_HOST}/tsm/v1alpha1/clusters/${CLUSTER_ID}/apps" \
#     -H 'Connection: keep-alive' \
#     -H 'Accept: application/json, text/plain, */*' \
#     -H 'Content-Type: application/json' \
#     -H "csp-auth-token: $AT" \
#     -H 'Accept-Language: en-US,en;q=0.9' | jq -r ".[].state")
# done


kubectl config use-context ${CLUSTER_NAME}-admin@${CLUSTER_NAME}

echo "Creating the cf-workloads namespace"
kubectl create ns $ACME_NAMESPACE --dry-run=client -o yaml | kubectl apply -f-

echo "Joining the Global Namespace, getting the current GNS def2"
GNSDEF=$(curl -s "https://${TSM_HOST}/tsm/v1alpha1/global-namespaces/${GNS_NAME}" \
  -X 'GET' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H "csp-auth-token: $AT" 
)


CLUSTER_IDS=$(curl -s "https://${TSM_HOST}/tsm/v1alpha1/clusters/" \
  -X 'GET' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H "csp-auth-token: $AT" 
)

# if [[ -z $GNSDEF ]]; then
#   GNSDEF="{code: 404}"
# fi

echo "appending the new cluster"
GNSDEF_APPEND="$(${TKG_LAB_SCRIPTS}/tsm_append_cluster_to_gnsdef.py "${GNSDEF}" ${GNS_NAME} ${GNS_DOMAIN} ${ACME_NAMESPACE} ${CLUSTER_NAME} ${CLUSTER_IDS})"

echo $GNSDEF_APPEND > /tmp/gnsdef_append



curl "https://${TSM_HOST}/tsm/v1alpha1/global-namespaces/${GNS_NAME}" \
  -X 'PUT' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H "csp-auth-token: $AT" \
  --data-binary "@/tmp/gnsdef_append" \
  --compressed

echo "Done"