#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 3 ]; then
  echo "Must supply cluster_name, metallb start and end ips as args"
  exit 1
fi

CLUSTER_NAME=$1
METALLB_START_IP=$2
METALLB_END_IP=$3

IAAS=$(yq r $PARAMS_YAML iaas)

if [ "$IAAS" = "aws" ];
then
  echo "Noop, as metallb is only used for vsphere"
else

  kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

  mkdir -p generated/$CLUSTER_NAME/metallb/

  # Deploy metalLB
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
  # On first install only
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"



  # Create Layer2 configuration
  cat > generated/$CLUSTER_NAME/metallb/metallb-configmap.yaml << EOF
  apiVersion: v1
  kind: ConfigMap
  metadata:
    namespace: metallb-system
    name: config
  data:
    config: |
      address-pools:
      - name: default
        protocol: layer2
        addresses:
        - $METALLB_START_IP-$METALLB_END_IP
EOF
  kubectl apply -f generated/$CLUSTER_NAME/metallb/metallb-configmap.yaml

fi