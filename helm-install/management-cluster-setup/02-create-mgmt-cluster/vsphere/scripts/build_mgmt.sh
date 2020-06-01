#!/bin/bash -e

./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/01-create-mgmt-cluster.sh
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/02-install-metallb.sh 
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/03a-install-external-dns.sh
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/03-install-contour.sh
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/vsphere/scripts/04-install-dex.sh
sleep 5s