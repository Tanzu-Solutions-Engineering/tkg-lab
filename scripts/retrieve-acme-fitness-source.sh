# bin/bash -e
rm -rf acme_fitness_demo
git clone https://github.com/vmwarecloudadvocacy/acme_fitness_demo.git
cd acme_fitness_demo
git checkout 158bbe2
cd ..
rm -rf acme_fitness_demo/.git
rm -rf acme_fitness_demo/aws-fargate
rm -rf acme_fitness_demo/docker-compose
