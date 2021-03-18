#!/bin/bash
set -o errexit

function random_string() {
  len=${1:-8}
  head -c 1024 /dev/urandom | base64 | tr -cd A-Za-z0-9 | head -c "$len"
}

function print_passwords() {
cat <<EOF
# [Required] The initial password of Harbor admin.
harborAdminPassword: $harborAdminPassword

# [Required] The secret key used for encryption. Must be a string of 16 chars.
secretKey: $secretKey

database:
  # [Required] The initial password of the postgres database.
  password: $databasePassword

core:
  # [Required] Secret is used when core server communicates with other components.
  secret: $coreSecret
  # [Required] The XSRF key. Must be a string of 32 chars.
  xsrfKey: $coreXsrfKey
jobservice:
  # [Required] Secret is used when job service communicates with other components.
  secret: $jobserviceSecret
registry:
  # [Required] Secret is used to secure the upload state from client
  # and registry storage backend.
  # See: https://github.com/docker/distribution/blob/master/docs/configuration.md#http
  secret: $registrySecret

Please copy the above randomly generated passwords and secrets into the data values yaml file.
EOF
}

function inject_passwords_inline() {
  yq e -i '.harborAdminPassword = env(harborAdminPassword)' "$1"
  yq e -i '.secretKey = env(secretKey)' "$1"
  yq e -i '.database.password = env(databasePassword)' "$1"
  yq e -i '.core.secret = env(coreSecret)' "$1"
  yq e -i '.core.xsrfKey = env(coreXsrfKey)' "$1"
  yq e -i '.jobservice.secret = env(jobserviceSecret)' "$1"
  yq e -i '.registry.secret = env(registrySecret)' "$1"
  # shellcheck disable=SC1004
  sed -i -e '3i\
---
' "$1"
  rm -f "$1-e"

  echo "Successfully generated random passwords and secrets in $1"
}

function install_yq() {
  if ! which yq >/dev/null; then
    echo 'Please install yq from https://github.com/mikefarah/yq'
    exit 1
  fi
}

# Generate random passwords and secrets
export harborAdminPassword=$(random_string 16)
export secretKey=$(random_string 16)
export databasePassword=$(random_string 16)
export coreSecret=$(random_string 16)
export coreXsrfKey=$(random_string 32)
export jobserviceSecret=$(random_string 16)
export registrySecret=$(random_string 16)

if [ $# = 0 ]; then
  print_passwords
else
  install_yq
  inject_passwords_inline "$1"
fi
