#!/bin/bash -e

./k8/scripts/velero/01-setup-aws-env-velero.sh
./k8/scripts/velero/02-install-velero-on-aws.sh
