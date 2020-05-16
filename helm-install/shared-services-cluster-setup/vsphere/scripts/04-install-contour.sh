#!/bin/bash -e

export CLUSTER_NAME=$(yq r $PARAM_FILE svcCluster.name)
./extensions/install-contour.sh
## check if ennoy service is running with external ip.
bash -c 'external_ip=""; while [ -z $external_ip ]; do echo "Waiting for end point..."; external_ip=$(kubectl get svc envoy -n tanzu-system-ingress --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); [ -z "$external_ip" ] && sleep 10; done; echo "End point ready-" && echo $external_ip; export endpoint=$external_ip'
./shared-services-cluster-setup/vsphere/scripts/create-record-set-svc.sh
