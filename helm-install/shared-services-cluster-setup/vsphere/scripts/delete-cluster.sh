
tkg delete cluster $(yq r $PARAM_FILE svcCluster.name) -v 5 --config=./k8/config.yaml