
tkg delete cluster $(yq r $PARAM_FILE wlCluster.name) -v 5 --config=./k8/config.yaml