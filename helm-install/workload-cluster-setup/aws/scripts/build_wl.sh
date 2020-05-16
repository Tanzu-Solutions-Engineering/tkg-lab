
./workload-cluster-setup/aws/scripts/01-create-workload-cluster.sh
sleep 5s 
./workload-cluster-setup/aws/scripts/02-install-certmanager.sh
sleep 5s
./workload-cluster-setup/aws/scripts/03-install-contour.sh
sleep 5s 
./workload-cluster-setup/aws/scripts/04-install-gangway.sh
sleep 5s
./workload-cluster-setup/aws/scripts/05-install-wavefront.sh
sleep 5s
./workload-cluster-setup/aws/scripts/06-install-fluent-bit.sh
sleep 5s