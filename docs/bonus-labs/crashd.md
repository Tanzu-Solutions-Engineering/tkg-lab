# Using crashd to retrieve diagnostics

Crashd is a diagnostics tool that will gather logs and additional information regarding your cluster and bundle them so that you can include this as an artifact for a support case or troubleshooting.

>Note: Currently crashd is only supported for vSphere and AWS.  Examples for both are listed in separate sections below.

## For TKG on AWS

The following lab walks through a series of commands that can be used to retrieve crashd data from TKG on AWS.  There is an added complexity here in that the AWS setup includes a bastion hosts to get to cluster nodes.

```bash
export CRASHD_VERSION=v0.3.7+vmware.2

# This shows retrieving the binary from internal source for pre-testing, however here is where to get the offical GA version
https://www.vmware.com/go/get-tkg

# Retrieve the binary package for pre-release versions...
curl --output /tmp/crashd-linux-amd64-$CRASHD_VERSION.tar.gz http://build-squid.eng.vmware.com/build/mts/release/bora-17672021/publish/lin64/tkg_release/crash-diagnostics-$CRASHD_VERSION/crashd/executables/crashd-linux-amd64-$CRASHD_VERSION.tar.gz

# Setup key variables
export MGMT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
export SSH_KEY=keys/$(yq e .environment-name $PARAMS_YAML)-ssh.pem
kubectl config use-context $MGMT_CLUSTER-admin@$MGMT_CLUSTER
export BASTION_IP=$(kubectl get awscluster -ojsonpath="{.items[0].status.bastion.addresses[?(@.type == 'ExternalIP')].address}" -n tkg-system)

# Create the crasd properties file
cat > /tmp/crashd-args.properties << EOF
target=mgmt
infra=aws
workdir=./workdir
ssh_user=ubuntu
ssh_pk_file=~/ssh-key.pem
mgmt_cluster_ns=tkg-system
mgmt_cluster_config=~/config
EOF
echo $CRASHD_VERSION > /tmp/crashd-version

# Transfer key files and values to the bastion host
scp -i $SSH_KEY -o StrictHostKeyChecking=no /tmp/crashd-linux-amd64-$CRASHD_VERSION.tar.gz  ubuntu@$BASTION_IP:
scp -i $SSH_KEY -o StrictHostKeyChecking=no /tmp/crashd-args.properties  ubuntu@$BASTION_IP:
scp -i $SSH_KEY -o StrictHostKeyChecking=no /tmp/crashd-version  ubuntu@$BASTION_IP:
scp -i $SSH_KEY -o StrictHostKeyChecking=no ~/.kube/config  ubuntu@$BASTION_IP:
scp -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_KEY ubuntu@$BASTION_IP:ssh-key.pem

# SSH to bastion host
ssh -i $SSH_KEY ubuntu@$BASTION_IP -o StrictHostKeyChecking=no
```

Now execute the following on bastion host

```bash
# Retrieve the version number
export CRASHD_VERSION=$(cat crashd-version)

# Install prerequsites kubectl and kind
sudo snap install kubectl --classic
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Extract crashd binary
tar -xvf crashd-linux-amd64-$CRASHD_VERSION.tar.gz 
sudo mv ./crashd/crashd-linux-amd64-$CRASHD_VERSION /usr/local/bin/crashd
cd crashd

# Run crashd
crashd run --args-file ~/crashd-args.properties diagnostics.crsh --debug

# Exit
exit
```

Now get the file and you can upload it into a ticket.

```bash
scp -i $SSH_KEY ubuntu@$BASTION_IP:crashd/tkg-mgmt.diagnostics.tar.gz /tmp/tkg-mgmt.diagnostics.tar.gz
```

## For TKG on vSphere

The following lab walks through a series of commands that can be used to retrieve crashd data from TKG assuming you have direct access from your macbook to the management cluster.  This was the case for me with vSphere (but not with AWS due to bastion host).

```bash
export CRASHD_VERSION=v0.3.7+vmware.2

# This shows retrieving the binary from internal source for pre-testing, however here is where to get the offical GA version
https://www.vmware.com/go/get-tkg

# Retrieve the binary package for pre-release versions...
curl --output /tmp/crashd-darwin-amd64-$CRASHD_VERSION.tar.gz http://build-squid.eng.vmware.com/build/mts/release/bora-17672021/publish/lin64/tkg_release/crash-diagnostics-$CRASHD_VERSION/crashd/executables/crashd-darwin-amd64-$CRASHD_VERSION.tar.gz

# Extract crashd binary
tar -xvf /tmp/crashd-darwin-amd64-$CRASHD_VERSION.tar.gz 
sudo mv crashd/crashd-darwin-amd64-$CRASHD_VERSION /usr/local/bin/crashd

# Setup key variables
export SSH_KEY_PATH=$(pwd)/keys/$(yq e .environment-name $PARAMS_YAML)-ssh
export MGMT_CLUSTER=$(yq e .management-cluster.name $PARAMS_YAML)
kubectl config use-context $MGMT_CLUSTER-admin@$MGMT_CLUSTER

# Create the crasd properties file
cat > /tmp/crashd-args-mgmt.properties << EOF
target=mgmt
infra=vsphere
workdir=/tmp/workdir
ssh_user=capv
ssh_pk_file=$SSH_KEY_PATH
mgmt_cluster_ns=tkg-system
mgmt_cluster_config=~/.kube/config
EOF

# Run crashd
crashd run --args-file /tmp/crashd-args-mgmt.properties crashd/diagnostics.crsh --debug

# Now for a workload cluster
export SS_CLUSTER=$(yq e .shared-services-cluster.name $PARAMS_YAML)
kubectl config use-context $MGMT_CLUSTER-admin@$MGMT_CLUSTER

# Create the crasd properties file
cat > /tmp/crashd-args-workload.properties << EOF
target=workload
infra=vsphere
workdir=/tmp/workdir
ssh_user=capv
ssh_pk_file=$SSH_KEY_PATH
mgmt_cluster_ns=tkg-system
mgmt_cluster_config=~/.kube/config
workload_clusters=$SS_CLUSTER
workload_cluster_ns=default
EOF

# Run crashd
crashd run --args-file /tmp/crashd-args-workload.properties crashd/diagnostics.crsh --debug

```

Now get the `tkg-mgmt.diagnostics.tar.gz` file at your project root and can upload it into a ticket.
