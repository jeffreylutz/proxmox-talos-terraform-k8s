#!/bin/bash

# set exit on error
set -e

[ $(id -u) -ne 0 ] && echo "ERROR:  Must be ran as root!!!" && exit 1

apt-get update
apt-get install -y curl jq arp-scan


# Install talosctl
curl -sL https://talos.dev/install | sh

# Install Terraform
apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform
terraform -version

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker jeff
