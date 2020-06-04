
date +"%r"

./management-cluster-setup/02-create-mgmt-cluster/aws/scripts/build_mgmt.sh
./shared-services-cluster-setup/aws/scripts/build_svc.sh
./workload-cluster-setup/aws/scripts/build_wl.sh

echo "Success!!"
date +"%r"