#bin/bash

mkdir -p clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated

# 04-fluent-bit-configmap.yaml
yq read tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml > clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml

sed -i '' -e 's/<TKG_CLUSTER_NAME>/mgmt/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<TKG_INSTANCE_NAME>/tkg-aws-lab/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<FLUENT_ELASTICSEARCH_HOST>/elasticsearch/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<FLUENT_ELASTICSEARCH_PORT>/9200/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
