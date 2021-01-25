#! /usr/bin/env bash

kapp deploy -a cert-manager -n tanzu-kapp -y -f tkg-extensions/cert-manager/
