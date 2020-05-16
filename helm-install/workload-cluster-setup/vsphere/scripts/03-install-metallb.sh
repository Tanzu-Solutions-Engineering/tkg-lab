#!/bin/bash -e

export METALLB_VALUES_FILE='../workload-cluster-setup/vsphere/lib/metallb_values.yaml'
./extensions/install-metallb.sh