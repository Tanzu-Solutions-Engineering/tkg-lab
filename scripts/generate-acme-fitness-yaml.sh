#!/bin/bash -e
: ${ACME_FITNESS_CN?"Need to set ACME_FITNESS_CN environment variable"}

# contour-cluster-issuer.yaml
yq write -d0 clusters/wlc-1/acme-fitness/generated/acme-fitness-frontend-ingress.yaml -i "spec.tls[0].hosts[0]" $ACME_FITNESS_CN  
yq write -d0 clusters/wlc-1/acme-fitness/generated/acme-fitness-frontend-ingress.yaml -i "spec.rules[0].host" $ACME_FITNESS_CN  
