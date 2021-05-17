#!/bin/bash -e

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

# Give some information timestamps to know how long things take
echo $(date)

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