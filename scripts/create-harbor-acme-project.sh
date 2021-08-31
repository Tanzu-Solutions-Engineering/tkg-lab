#!/usr/bin/env bash

set -x

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh >/dev/null 2>&1

export HARBOR_USERNAME=$(yq e .harbor.admin-user $PARAMS_YAML )
export HARBOR_PASSWORD=$(yq e .harbor.admin-password $PARAMS_YAML )
export HARBOR_HOST=$(yq e .harbor.harbor-cn $PARAMS_YAML )
ACME_PROJECT_NAME=$(yq e .acme-fitness.harbor-project $PARAMS_YAML )

ret="$($TKG_LAB_SCRIPTS/harbor-manage-projects.py create $ACME_PROJECT_NAME)"

if [ $? -ne 0 ]
then
    echo $ret
    exit 1
fi

projid=$(echo $ret | jq -r .status.projectid)

mkdir -p generated/harbor
echo "acme-harbor-project-id: ${projid}" > generated/harbor/acme-harbor-project-id.yaml
