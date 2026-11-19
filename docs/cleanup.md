# Clean-up (avoid unexpected charges)

Delete in this order:
1. Terminate EC2 (Mumbai + Singapore recovered instance).
2. Delete RDS instances `dr-mumbai-mysql`, `dr-singapore-mysql-restored` and their snapshots.
3. Delete EFS mount targets, then `Mumbai-Shared-EFS`.
4. Delete EBS volumes (including restored volume) and snapshots; delete DLM policy.
5. Deregister AMIs and delete their snapshots (both Regions).
6. Delete AWS Backup recovery points, then plans and vaults.
7. Empty and delete both S3 buckets (remove replication + lifecycle first).
8. Delete VPC resources (IGW, subnets, route tables, security groups, VPC).
