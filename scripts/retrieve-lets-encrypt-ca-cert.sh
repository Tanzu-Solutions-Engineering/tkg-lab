#!/bin/bash -e

curl https://letsencrypt.org/certs/isrg-root-x1-cross-signed.pem -o keys/letsencrypt-ca.pem

# Remove the carriage return character that lets encrypt pem file has as a line ending
if [ `uname -s` = 'Darwin' ];
then
    sed -i '' $'s/\x0D//' keys/letsencrypt-ca.pem
else
    sed -i -e $'s/\x0D//' keys/letsencrypt-ca.pem
fi

chmod 600 keys/letsencrypt-ca.pem