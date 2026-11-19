#!/bin/bash
# Mount EFS on an EC2 instance. Replace the target with the EFS DNS name or a mount-target IP.
set -e
TARGET="<EFS_DNS_OR_MOUNT_TARGET_IP>"
sudo dnf install -y nfs-utils
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${TARGET}:/ /mnt/efs
sudo mkdir -p /mnt/efs/DR-Project
echo "EFS successfully mounted" | sudo tee /mnt/efs/DR-Project/test.txt
df -h | grep efs
