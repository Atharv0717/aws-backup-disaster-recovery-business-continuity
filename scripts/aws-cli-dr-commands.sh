#!/bin/bash
# Reference commands - replace <placeholders> before running.
# 1) Manual EBS snapshot
aws ec2 create-snapshot --region ap-south-1 --volume-id <vol-id> --description "DR-Mumbai-EC2-A-Data-Volume-Manual-Backup"
# 2) Create AMI and copy to Singapore
aws ec2 create-image --region ap-south-1 --instance-id <i-id> --name Mumbai-EC2-A-AMI --no-reboot
aws ec2 copy-image --region ap-southeast-1 --source-region ap-south-1 --source-image-id <ami-id> --name DR-Singapore-EC2-A-AMI
# 3) RDS manual snapshot
aws rds create-db-snapshot --region ap-south-1 --db-instance-identifier dr-mumbai-mysql --db-snapshot-identifier dr-mumbai-mysql-manual-snapshot
# 4) Create backup vaults
aws backup create-backup-vault --region ap-south-1 --backup-vault-name Mumbai-Backup-Vault
aws backup create-backup-vault --region ap-southeast-1 --backup-vault-name Singapore-DR-Vault
# 5) List backup jobs
aws backup list-backup-jobs --region ap-south-1 --by-state COMPLETED
