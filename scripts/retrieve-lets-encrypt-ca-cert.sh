#!/bin/bash -e

curl https://letsencrypt.org/certs/lets-encrypt-r3-cross-signed.pem -o keys/letsencrypt-ca.pem
     
chmod 600 keys/letsencrypt-ca.pem