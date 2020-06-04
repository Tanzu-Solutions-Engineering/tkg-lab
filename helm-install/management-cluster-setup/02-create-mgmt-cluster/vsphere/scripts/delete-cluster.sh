
export VSPHERE_SERVER=$(yq r $PARAM_FILE vsphere.vcenterserver)
export VSPHERE_USERNAME=$(yq r $PARAM_FILE vsphere.vcenterUser)
export VSPHERE_PASSWORD=$(yq r $PARAM_FILE vsphere.vcenterPwd)

tkg delete management-cluster -v 5 --config=./k8/config.yaml