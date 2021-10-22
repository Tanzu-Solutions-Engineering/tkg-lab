#!/bin/bash -e

curl https://letsencrypt.org/certs/isrg-root-x1-cross-signed.pem -o keys/letsencrypt-ca.pem
     
chmod 600 keys/letsencrypt-ca.pem