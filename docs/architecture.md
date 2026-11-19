# Architecture

<p align="center"><img src="../architecture/aws-multi-region-backup-architecture.png" width="950" alt="Reference architecture"></p>

## Design goals
1. Survive failure of a single resource (instance, volume, database).
2. Survive failure of an Availability Zone (two AZs, shared EFS, Multi-AZ-ready subnets).
3. Survive failure of a whole Region (cross-Region AMI, S3 replication, backup copy, RDS snapshot restore).

## Network
| Item | Mumbai (ap-south-1) | Singapore (ap-southeast-1) |
|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.20.0.0/16 |
| Public subnets | 10.0.1.0/24 (1a), 10.0.2.0/24 (1b) | recovered EC2 subnet |
| Private subnets | 10.0.11.0/24 (1a), 10.0.12.0/24 (1b) | - |
| Internet access | Internet Gateway on public route table | Internet Gateway |
| Private route table | local route only (isolated DB tier) | - |

<p align="center"><img src="../screenshots/01_Mumbai_VPC_Resource-Map.png" width="880" alt="Mumbai VPC resource map"><br><sub><b>Figure 01</b> – Mumbai VPC resource map</sub></p>
<p align="center"><img src="../screenshots/02_Mumbai_VPC_Resource-Map-Subnets-RouteTables.png" width="880" alt="Subnets and route tables"><br><sub><b>Figure 02</b> – Subnets and route tables</sub></p>
<p align="center"><img src="../screenshots/03_Singapore_VPC_Resource-Map.png" width="880" alt="Singapore VPC resource map"><br><sub><b>Figure 03</b> – Singapore VPC resource map</sub></p>

## Data protection layers
```mermaid
flowchart TB
  A[Application data] --> B[EBS snapshot - DLM daily]
  A --> C[AWS Backup daily plan]
  A --> D[AMI - golden image]
  A --> E[EFS automatic backups]
  A --> F[S3 versioning + CRR]
  A --> G[RDS snapshot]
  B --> H[(Mumbai vault)]
  C --> H
  H -- cross-Region copy --> I[(Singapore-DR-Vault)]
  D -- AMI copy --> J[Singapore AMI]
  F -- replication --> K[Singapore bucket]
  G -- snapshot copy --> L[Singapore RDS restore]
```

## Security
- Security groups per tier (web, EFS, RDS) with least-privilege rules.
- EFS encrypted with KMS (`aws/elasticfilesystem`); AWS Backup vault encrypted with KMS.
- DLM uses `AWSDataLifecycleManagerDefaultRole`; AWS Backup uses its service role.
- RDS lives in private subnets (DB subnet group `dr-mumbai-rds-subnet-group`).

<p align="center"><img src="../screenshots/06_Mumbai_SecurityGroup_RDS-SG-Details.png" width="880" alt="RDS security group"><br><sub><b>Figure 06</b> – RDS security group</sub></p>
<p align="center"><img src="../screenshots/37_Mumbai_RDS_Subnet-Group.png" width="880" alt="RDS subnet group - two private subnets in two AZs"><br><sub><b>Figure 37</b> – RDS subnet group - two private subnets in two AZs</sub></p>
