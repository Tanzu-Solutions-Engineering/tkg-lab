#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

export CLUSTER_NAME=$1

IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" != "vsphere" ];
then
  echo "Noop, as manual ako deployment is only used for vsphere"
else

  kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

  mkdir -p generated/$CLUSTER_NAME/avi/

  DATA_NETWORK_CIDR=$(yq e .avi.avi-data-network-cidr $PARAMS_YAML)
  export DATA_NETWORK_SUBNET=`echo $DATA_NETWORK_CIDR | cut -d'/' -f 1`
  export DATA_NETWORK_PREFIX=`echo $DATA_NETWORK_CIDR | cut -d'/' -f 2`
  export DATA_NETWORK=$(yq e .avi.avi-data-network $PARAMS_YAML)
  export CONTROLLER_HOST=$(yq e .avi.avi-controller $PARAMS_YAML)
  export NSX_ALB_USERNAME=$(yq e .avi.avi-username $PARAMS_YAML)
  export NSX_ALB_PASSWORD=$(yq e .avi.avi-password $PARAMS_YAML)
  export NSX_ALB_CA=$(yq e .avi.avi-ca-data $PARAMS_YAML | base64 --decode)

  cp avi/values-template.yaml generated/$CLUSTER_NAME/avi/values.yaml

  yq e -i ".AKOSettings.clusterName = env(CLUSTER_NAME)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".NetworkSettings.subnetIP = env(DATA_NETWORK_SUBNET)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".NetworkSettings.subnetPrefix = env(DATA_NETWORK_PREFIX)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".NetworkSettings.networkName = env(DATA_NETWORK)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".ControllerSettings.controllerHost = env(CONTROLLER_HOST)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".avicredentials.username = env(NSX_ALB_USERNAME)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".avicredentials.password = env(NSX_ALB_PASSWORD)" generated/$CLUSTER_NAME/avi/values.yaml
  yq e -i ".avicredentials.certificateAuthorityData = strenv(NSX_ALB_CA)" generated/$CLUSTER_NAME/avi/values.yaml

  kubectl apply -f avi/namespace.yaml

  helm repo add ako https://projects.registry.vmware.com/chartrepo/ako
  
  helm repo update

  helm template ako ako/ako \
    --namespace avi-system \
    --values generated/$CLUSTER_NAME/avi/values.yaml \
    --version 1.3.4 \
    --skip-tests \
    --include-crds | 
    ytt -f - -f avi/image-overlay.yaml --ignore-unknown-comments > generated/$CLUSTER_NAME/avi/manifests.yaml
  
  kubectl apply -f generated/$CLUSTER_NAME/avi/manifests.yaml

fi