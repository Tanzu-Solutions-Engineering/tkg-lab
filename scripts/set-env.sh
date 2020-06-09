#!/bin/bash -e

if [ -z "$PARAMS_YAML" ];then
    export PARAMS_YAML="secrets/params.yaml"
fi
