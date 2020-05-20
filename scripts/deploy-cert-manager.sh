# bin/bash

kubectl apply -f tkg-extensions/cert-manager/
#All 3 pods need to be running
while kubectl get po -n cert-manager | grep Running | wc -l | grep 3 ; [ $? -ne 0 ]; do
    echo Cert Manager is not yet ready
    sleep 5s
done
