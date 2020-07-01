#!/bin/bash -e

export METALLB_VALUES_FILE='./management-cluster-setup/02-create-mgmt-cluster/vsphere/lib/metallb_values.yaml'
./extensions/install-metallb.sh