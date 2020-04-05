# Install Contour on management cluster

```bash
kubectl apply -f tkg-extensions/ingress/contour/aws/
```

Get the load balancer external IP for the envoy service

```bash
kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Update **dns/tkg-aws-lab-record-sets.yaml** wildcard management `*.mgmt` entry with your dns name and rrdatas.

Update Google Cloud DNS

```bash
gcloud dns record-sets import dns/tkg-aws-lab-record-sets.yml \
  --zone tkg-aws-lab \
  --delete-all-existing
```