#!/bin/bash -e

./shared-services-cluster-setup/vsphere/scripts/01-create-workload-cluster.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/02-install-certmanager.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/03-install-metallb.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/04-install-contour.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/05-install-gangway.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/06-install-wavefront.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/07-install-elasticsearch-kibana.sh
sleep 5s
./shared-services-cluster-setup/vsphere/scripts/08-install-fluent-bit.sh 
sleep 5s
