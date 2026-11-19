#!/bin/bash
# Format and mount an additional EBS volume on /data (check device name with lsblk first)
set -e
lsblk
sudo mkfs -t xfs /dev/nvme1n1
sudo mkdir -p /data
sudo mount /dev/nvme1n1 /data
echo "AWS EBS storage verification" | sudo tee /data/ebs-test.txt
df -h
