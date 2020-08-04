#!/bin/bash -e

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
EMAIL=$(yq r $PARAMS_YAML lets-encrypt-acme-email)
DOMAIN=$(yq r $PARAMS_YAML subdomain)



mkdir -p generated/$CLUSTER_NAME/gitlab

# 01-namespace.yaml
yq read gitlab/01-namespace.yaml > generated/$CLUSTER_NAME/gitlab/01-namespace.yaml

# gitlab-values.yaml
yq read gitlab/gitlab-values.yaml > generated/$CLUSTER_NAME/gitlab/gitlab-values.yaml
yq write generated/$CLUSTER_NAME/gitlab/gitlab-values.yaml -i "certmanager-issuer.email" "$EMAIL"
yq write generated/$CLUSTER_NAME/gitlab/gitlab-values.yaml -i "global.hosts.domain"  "$CLUSTER_NAME.$DOMAIN" 

