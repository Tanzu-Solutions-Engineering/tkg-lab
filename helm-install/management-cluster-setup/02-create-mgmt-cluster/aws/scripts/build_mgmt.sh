#!/bin/bash -e

./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/00-bootstrap-aws.sh
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/01-create-mgmt-cluster.sh
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/02-install-contour.sh
sleep 5s
./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/03-install-dex.sh
sleep 5s