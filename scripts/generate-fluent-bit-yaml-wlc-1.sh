#bin/bash

mkdir -p clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated

# 04-fluent-bit-configmap.yaml
yq read tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml > clusters/wlc-1/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml

sed -i '' -e 's/<TKG_CLUSTER_NAME>/wlc-1/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<TKG_INSTANCE_NAME>/tkg-aws-lab/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<FLUENT_ELASTICSEARCH_HOST>/'$ELASTICSEARCH_CN'/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
sed -i '' -e 's/<FLUENT_ELASTICSEARCH_PORT>/80/g' clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/generated/04-fluent-bit-configmap.yaml
