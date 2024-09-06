#!/bin/bash

set -e -x

BASE_DIR=$PWD

ENVOY_TAG=$(cat envoy-release/tag)

pushd ci/diego-release/tasks/create-envoy-blob

echo "${GCP_KEY}" > gcp.key

cat << EOF >> vars.tfvars
project_id = "cf-diego-pivotal"
zone = "us-central1-a"
region = "us-central1"
env_id = "env-$(date +%Y-%m-%dt%H-%M)"
credentials = "${PWD}/gcp.key"
gce_ssh_user = "pivotal"
gce_ssh_pub_key_file = "/tmp/id_rsa_gcp.pub"
EOF

function cleanup {
  pushd "${BASE_DIR}/ci/diego-release/tasks/create-envoy-blob"
  if [ -f terraform.tfstate ]; then
    terraform destroy -var-file="vars.tfvars" -auto-approve
  fi
  popd
}

function run_remotely {
  ip=$1
  cmd=$2
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /tmp/id_rsa_gcp pivotal@"${ip}" "${cmd}"
}

function copy_file {
  ip=$1
  filename=$2
  destination=$3
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /tmp/id_rsa_gcp "pivotal@${ip}:${filename}" "${destination}"
}

trap cleanup EXIT

ssh-keygen -N "" -f /tmp/id_rsa_gcp

terraform init
terraform apply -var-file="vars.tfvars" -auto-approve

# Wait for VM to boot
sleep 60

VM_IP=$(terraform output --raw external_ip)

# Install docker and enable ipv6 in docker
# https://docs.docker.com/engine/install/ubuntu/
# https://docs.docker.com/config/daemon/ipv6/
run_remotely "${VM_IP}" '
sudo apt-get update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    acl \
    postgresql \
    openssl
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes --always-trust -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  xenial stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io zstd
sudo setfacl --modify user:pivotal:rw /var/run/docker.sock

sudo bash -c "cat >> /etc/docker/daemon.json" << EOF
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}
EOF
sudo service docker restart
'

# Build envoy
run_remotely "${VM_IP}" "
git clone https://github.com/envoyproxy/envoy
cd envoy
git checkout ${ENVOY_TAG}
sed -i '/\"envoy.transport_sockets.tcp_stats\":.*\"\\/\\/source\\/extensions\\/transport_sockets\\/tcp_stats:config\",/d' source/extensions/extensions_build_config.bzl
IMAGE_NAME=${IMAGE_NAME} ENVOY_DOCKER_OPTIONS='--network=host' BAZEL_BUILD_EXTRA_OPTIONS='--flaky_test_attempts=10' ./ci/run_envoy_docker.sh './ci/do_ci.sh bazel.release'
"

popd

run_remotely "${VM_IP}" "zstd -d /tmp/envoy-docker-build/envoy/x64/bin/release.tar.zst"
run_remotely "${VM_IP}" "tar -C /tmp -xf /tmp/envoy-docker-build/envoy/x64/bin/release.tar envoy"
copy_file "${VM_IP}" "/tmp/envoy" "${BASE_DIR}/envoy-binary/envoy"
copy_file "${VM_IP}" "envoy/LICENSE" "${BASE_DIR}/envoy-binary/LICENSE"
copy_file "${VM_IP}" "envoy/NOTICE" "${BASE_DIR}/envoy-binary/NOTICE"

pushd envoy-binary
  chmod 755 envoy
  tar -czf envoy.tgz envoy LICENSE NOTICE
popd
