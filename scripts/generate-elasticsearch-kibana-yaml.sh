#bin/bash

# Following environment variables are required: ELASTICSEARCH_CN, KIBANA_CN

# 03b-ingress.yaml
yq write -d0 clusters/mgmt/elasticsearch-kibana/generated/03b-ingress.yaml -i "spec.rules[0].host" $ELASTICSEARCH_CN

# 04-kibana.yaml
yq write -d2 clusters/mgmt/elasticsearch-kibana/generated/04-kibana.yaml -i "spec.rules[0].host" $KIBANA_CN
