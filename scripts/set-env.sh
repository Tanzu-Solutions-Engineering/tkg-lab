#!/bin/bash -e

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

add_yaml_doc_seperator() {
if [ `uname -s` = 'Darwin' ];
then
  sed -i '' '3i\
---\
' $1
else
  sed -i -e '3i\---\' $1
fi
}