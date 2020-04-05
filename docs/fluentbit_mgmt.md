# Install fluent bit

```bash
cp tkg-extensions-mods-examples/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
```

Update clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml.  Find *elasticsearch.mgmt.tkg-aws-lab.winterfell.live* and replace with your elasticsearch URL.

```bash
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/00-fluent-bit-namespace.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/01-fluent-bit-service-account.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/02-fluent-bit-role.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/03-fluent-bit-role-binding.yaml
# Using modified version below
kubectl apply -f clusters/mgmt/tkg-extensions-mods/logging/fluent-bit/aws/output/elasticsearch/04-fluent-bit-configmap.yaml
kubectl apply -f tkg-extensions/logging/fluent-bit/aws/output/elasticsearch/05-fluent-bit-ds.yaml
```

## Validation Step

Ensure that fluent bit pods are running

```bash
kubectl get pods -n tanzu-system-logging
```

Access kibana.  This leverages the wildcard DNS entry on the convoy ingress.  Your base domain will be different than mine.

```bash
open http://logs.mgmt.tkg-aws-lab.winterfell.live
```

You should see the kibana welcome screen.  

Click the Discover icon at the top of the right menu bar.

You will see widget to create an index pattern.  Enter `logstash-*` and click `next step`.

Select `@timestamp` for the Time filter field name. and then click `Create index pattern`

Now click the Discover icon at the top of the right menu bar.  You can start searching for logs.