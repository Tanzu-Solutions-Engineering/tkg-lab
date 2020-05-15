#!/bin/bash -e

kubectl apply -f tkg-extensions/ingress/contour/aws/
sleep 10s #Wait a sec to get DNS/IP assigned
