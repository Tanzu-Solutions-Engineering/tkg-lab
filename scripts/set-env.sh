#!/bin/bash -e

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

# Give some information timestamps to know how long things take
echo $(date)

# YQ versions before 4.11.1 would remove document seperator when updating docs
# the issue has been fixed, but keeping this function in place to handle either condition
add_yaml_doc_seperator() {
# the sed command retrieves the 3rd line of the file then grep tests for doc seperator
# yq < 4.11 would strip the doc sperator, so this function would put it back
if sed '3q;d' $1 | grep "\-\-\-"; then  
  echo "Doc seperator already present, noop"
else
  echo "Adding document seperator"
  if [ `uname -s` = 'Darwin' ];
  then
    sed -i '' '3i\
---\
' $1
  else
    sed -i -e '3i\---\' $1
  fi
fi
}