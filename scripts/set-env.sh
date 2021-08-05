#!/bin/bash -e

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

# Give some information timestamps to know how long things take
echo $(date)

# YQ versions before 4.11.1 would remove document seperator when updating docs
# the issue has been fixed, but keeping this function in place to handle either condition
add_yaml_doc_seperator() {
if grep "\-\-\-" $1; then  
  echo "Skipping, adding document seperator"
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