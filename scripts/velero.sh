#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster name as arg"
  exit 1
fi

echo "Beginning Velero install..."

CLUSTER_NAME=$1
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

VELERO_BUCKET=$(yq r $PARAMS_YAML velero.bucket)
VELERO_REGION=$(yq r $PARAMS_YAML velero.region)
IAAS=$(yq e .iaas $PARAMS_YAML)

if [ "$IAAS" = "vsphere" ];
then

  # Begin Hack
  # The following hack is required because the vSphere Plugin is looking for a secret with the name “vsphere-config-secret“. This secret contains 
  # the vCenter Server credentials and config. In TKG, the secret used has a different name, and therefore cannot be found.
  # this is currently under review with the vSphere Plugin team to see if we can address this issue.
  # Nevertheless, there is an easy workaround for it, simply create another secret with the name “vsphere-config-secret” and the required information.
  # See https://beyondelastic.com/2020/04/30/backup-and-migrate-tkgi-pks-to-tkg-with-velero/ for where this issue was identified
  VSPHERE_SERVER=$(yq r $PARAMS_YAML vsphere.server)
  VSPHERE_USERNAME=$(yq r $PARAMS_YAML vsphere.username)
  VSPHERE_PASSWORD=$(yq r $PARAMS_YAML vsphere.password)

  mkdir -p generated/$CLUSTER_NAME/velero/

  cat > generated/$CLUSTER_NAME/velero/csi-vsphere.conf <<EOF
[Global]
cluster-id = "$CLUSTER_NAME"

[VirtualCenter "$VSPHERE_SERVER"]
insecure-flag = "true"
user = "$VSPHERE_USERNAME"
password = "$VSPHERE_PASSWORD"
port = "443"
EOF

  kubectl create secret generic vsphere-config-secret \
    --from-file=generated/$CLUSTER_NAME/velero/csi-vsphere.conf \
    --namespace=kube-system
  # End Hack

  velero install \
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.0.1,vsphereveleroplugin/velero-plugin-for-vsphere:1.0.0 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
  velero snapshot-location create vsl-vsphere --provider velero.io/vsphere

else
  velero install \
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.0.1 \
      --bucket $VELERO_BUCKET \
      --backup-location-config region=$VELERO_REGION \
      --snapshot-location-config region=$VELERO_REGION \
      --secret-file keys/credentials-velero
fi

# Wait for it to be ready
while kubectl get po -n velero | grep Running ; [ $? -ne 0 ]; do
	echo Velero is not yet ready
	sleep 5s
done

# Setup the backup schedule
if [ "$IAAS" = "vsphere" ];
then
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *" \
    --volume-snapshot-locations vsl-vsphere
else
  velero schedule create daily-$CLUSTER_NAME-cluster-backup \
    --schedule "0 7 * * *" 
fi