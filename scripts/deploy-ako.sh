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

  mkdir -p generated/$CLUSTER_NAME/ako/

  DATA_NETWORK_CIDR=$(yq e .avi.avi-data-network-cidr $PARAMS_YAML)
  export DATA_NETWORK_SUBNET=`echo $DATA_NETWORK_CIDR | cut -d'/' -f 1`
  export DATA_NETWORK_PREFIX=`echo $DATA_NETWORK_CIDR | cut -d'/' -f 2`
  export DATA_NETWORK=$(yq e .avi.avi-data-network $PARAMS_YAML)
  export CONTROLLER_HOST=$(yq e .avi.avi-controller $PARAMS_YAML)
  export NSX_ALB_USERNAME=$(yq e .avi.avi-username $PARAMS_YAML)
  export NSX_ALB_PASSWORD=$(yq e .avi.avi-password $PARAMS_YAML)
  export NSX_ALB_CA=$(yq e .avi.avi-ca-data $PARAMS_YAML | base64 --decode)

  cp nsxalb/values-template.yaml generated/$CLUSTER_NAME/ako/values.yaml

  yq e -i ".AKOSettings.clusterName = env(CLUSTER_NAME)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".NetworkSettings.subnetIP = env(DATA_NETWORK_SUBNET)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".NetworkSettings.subnetPrefix = env(DATA_NETWORK_PREFIX)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".NetworkSettings.networkName = env(DATA_NETWORK)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".ControllerSettings.controllerHost = env(CONTROLLER_HOST)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".avicredentials.username = env(NSX_ALB_USERNAME)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".avicredentials.password = env(NSX_ALB_PASSWORD)" generated/$CLUSTER_NAME/ako/values.yaml
  yq e -i ".avicredentials.certificateAuthorityData = strenv(NSX_ALB_CA)" generated/$CLUSTER_NAME/ako/values.yaml

  kubectl apply -f nsxalb/namespace.yaml

  helm repo add ako https://avinetworks.github.io/avi-helm-charts/charts/stable/ako
  helm repo update

  helm template ako --namespace avi-system ako/ako -f generated/$CLUSTER_NAME/ako/values.yaml --skip-tests | 
    ytt -f - -f nsxalb/image-overlay.yaml --ignore-unknown-comments | kubectl apply -f -

fi