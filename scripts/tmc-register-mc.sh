#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

IAAS=$(yq e .iaas $PARAMS_YAML)
TMC_CLUSTER_GROUP=$(yq e .tmc.cluster-group $PARAMS_YAML)

if tmc system context current | grep -q IDToken; then
  echo "Currently logged into TMC."
else
  echo "Please login to tmc before you continue."
  exit 1
fi

if tmc clustergroup list | grep -q $TMC_CLUSTER_GROUP; then
  echo "Cluster group $TMC_CLUSTER_GROUP found."
else
  echo "Cluster group $TMC_CLUSTER_GROUP not found.  Automattically creating it."
  tmc clustergroup create -n $TMC_CLUSTER_GROUP
fi

# Currently TMC cluster lifecycle management for TKG on vSphere only works with Photon OS.
if [ "$IAAS" == "vsphere" ];
then
  NODE_OS=$(yq e .vsphere.node-os $PARAMS_YAML)
  if [ "$NODE_OS" == "ubuntu" ];
  then
    echo "Warning! Please note, although you management cluster will be registered, TMC features associated to the management cluster on vsphere are only supported for Photon OS."
  fi
fi

mkdir -p generated/$CLUSTER_NAME/tmc

REGISTER=true

if tmc managementcluster list | grep -q $CLUSTER_NAME; then
  if [ "$(tmc managementcluster get $CLUSTER_NAME | yq e '.status.phase' -)" == "READY" ]; then
    echo "Management Cluster is already registered and ready."
    REGISTER=false
  else
    echo "Management Cluster is already registered and not READY, likely an old reference.  Will deregistery and re-register."
    echo "Deregistering managemnet cluster."

    # HACK: Kubeconfig should not be required, OLYMP-26147 has been created address this.  Set current context to managment cluster
    kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
    tmc managementcluster deregister $CLUSTER_NAME --force --kubeconfig ~/.kube/config

    while tmc managementcluster list | grep -q $CLUSTER_NAME; do
      echo Waiting for management cluster to finish deregistering.
      sleep 5
    done

  fi
fi

if $REGISTER; then
  echo "Registering management cluster now."
  tmc managementcluster register $CLUSTER_NAME \
    --default-cluster-group $TMC_CLUSTER_GROUP \
    --kubernetes-provider-type TKG

  TMC_REGISTRATION_URL=$(tmc managementcluster get $CLUSTER_NAME | yq e .status.registrationUrl -)

  # tanzu management-cluster register command has been removed since v1.4.1
  kubectl apply -f $TMC_REGISTRATION_URL

  echo "$CLUSTER_NAME registered as management-cluster with TMC"

  mv k8s-register-manifest.yaml generated/$CLUSTER_NAME/tmc/

  while [ "$(tmc managementcluster get $CLUSTER_NAME | yq e '.status.phase' -)" != "READY" ]; do
    echo Waiting for management cluster to have registration status of READY.
    sleep 5
  done

fi
