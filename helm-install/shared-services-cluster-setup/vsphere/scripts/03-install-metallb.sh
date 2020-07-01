#!/bin/bash -e

export METALLB_VALUES_FILE='./shared-services-cluster-setup/vsphere/lib/metallb_values.yaml'
./extensions/install-metallb.sh