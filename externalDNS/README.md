# External DNS

External DNS makes resources discoverable via public DNS. It eliminates some of the scripting updating dns records. External DNS can be used with different cloud providers. This Lab assumes that you a a cluster ready without ingress.

You can use External DNS with Ingresses and Services both. For contour HTTPProxy is not supported but IngressRoute is. Since we are using HTTProxy we can use anotations on envoy service to add a wild card entry.
External DNS is deployed to a cluster and you can run it locally as well.

### AWS

Create hosted Zone.
```bash
export HOSTED_ZONE=<your hosted zone name>
aws route53 create-hosted-zone --name "$HOSTED_ZONE" --caller-reference "external-dns-test-$(date +%s)"
```

Check if hosted zone is created successfully.

```bash
aws route53 list-hosted-zones-by-name --output json --dns-name "$HOSTED_ZONE" | jq -r '.HostedZones[0].Id'
```

### Running it locally.

```bash
git clone https://github.com/kubernetes-sigs/external-dns.git && cd external-dns
```

This will create external-dns in the build directory directly from master. You can add external-dns to your path.

```bash
cp ./build/external-dns /usr/local/bin/
```

```bash
kubectl run nginx --image=nginx --replicas=1 --port=80
kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer
```

Add annotation to nginx service.

```bash
export DNS=<Your dns>
kubectl annotate service nginx "external-dns.alpha.kubernetes.io/hostname=$DNS."
```
Add entry to aws hosted zone.

```bash
export HOSTED_ZONE_ID=<Your AWS hosted Zone>
external-dns --registry txt --provider aws --registry=txt --source service --txt-owner-id $HOSTED_ZONE_ID
```
Check your DNS by login into AWS console route 53 under your hosted zone.

### Deploy to a Cluster.

### Manual Steps: 

You can create below policy using aws cli or execute provided script below.

```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```
 or Execute below script.

```bash
 ./aws/create-externaldns-policy.sh
```

### IAM Role

You need to create an IAM Role. Once you create above policy(AllowExternalDNSUpdates) you can attach it to the role. You can use below script to add it to clusterawsadm cli.

```bash
export AWS_ACCOUNT_ID=<your aws account id>
clusterawsadm alpha bootstrap create-stack --extra-controlplane-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates \
--extra-node-policies arn:aws:iam::$AWS_ACCOUNT_ID:policy/AllowExternalDNSUpdates
```
Once you have Cluster up and running you can deploy External-dns using below scripts.


Replace $HOSTED_ZONE_ID with your hosted zone id in below yaml files.

### AWS
```bash
kubectl apply -f ./aws/deployment-aws.yaml
```
### vSphere

```bash
export AWS_ACCESS_KEY_ID=<aws access key>
export AWS_SECRET_ACCESS_KEY=<secret key>

kubectl create secret generic external-dns-iam-keys --from-literal=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID --from-literal=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
kubectl apply -f ./aws/deployment-vsphere.yaml
```

### Using single script after you create and attach policy to the role. Make sure to fill out params.yaml file.

./aws/deploy.sh <cluster name to use to switch kubectl context>

## Test External DNS.

Replace <your dns here> with the acutal dns name.

```bash

apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: <your dns here>
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
    targetPort: 80
  selector:
    app: nginx

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
          name: http
```

After few mins check if DNS record is created. Replace <your hosted zone id> with your hosted zone and <your dns> with your dns.

```bash
aws route53 list-resource-record-sets --output json --hosted-zone-id "/hostedzone/<your hosted zone id>" \
--query "ResourceRecordSets[?Name == '<your dns>']|[?Type == 'A']"
```

