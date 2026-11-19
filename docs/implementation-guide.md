# Implementation Guide (Step by Step)

Region names: **Mumbai = ap-south-1 (primary)**, **Singapore = ap-southeast-1 (DR)**. Date of build: 18 Nov 2026.

---
## Phase 1 - Networking (VPC, subnets, route tables)
1. Create `Mumbai-VPC` (10.0.0.0/16) and 4 subnets: Public-1 10.0.1.0/24 (1a), Public-2 10.0.2.0/24 (1b), Private-1 10.0.11.0/24 (1a), Private-2 10.0.12.0/24 (1b).
2. Create `Mumbai-Public-RT` (local + Internet Gateway) and `Mumbai-Private-RT` (local only); associate two subnets each.
3. Repeat in Singapore with VPC 10.20.0.0/16.

<p align="center"><img src="../screenshots/01_Mumbai_VPC_Resource-Map.png" width="880" alt="Mumbai VPC resource map"><br><sub><b>Figure 01</b> – Mumbai VPC resource map</sub></p>
<p align="center"><img src="../screenshots/02_Mumbai_VPC_Resource-Map-Subnets-RouteTables.png" width="880" alt="Mumbai - subnets, route tables and network connections"><br><sub><b>Figure 02</b> – Mumbai - subnets, route tables and network connections</sub></p>
<p align="center"><img src="../screenshots/03_Singapore_VPC_Resource-Map.png" width="880" alt="Singapore VPC resource map"><br><sub><b>Figure 03</b> – Singapore VPC resource map</sub></p>
<p align="center"><img src="../screenshots/04_Singapore_VPC_Resource-Map-Subnets-RouteTables.png" width="880" alt="Singapore - subnets, route tables and network connections"><br><sub><b>Figure 04</b> – Singapore - subnets, route tables and network connections</sub></p>

## Phase 2 - Security groups
Create one security group per tier (web, EFS, RDS) and allow only the required ports (HTTP/SSH for web, NFS 2049 for EFS, MySQL 3306 from the web tier for RDS).

<p align="center"><img src="../screenshots/05_Mumbai_SecurityGroup_SG-094d-Details.png" width="880" alt="Mumbai security group details"><br><sub><b>Figure 05</b> – Mumbai security group details</sub></p>
<p align="center"><img src="../screenshots/06_Mumbai_SecurityGroup_RDS-SG-Details.png" width="880" alt="Mumbai-RDS-SG"><br><sub><b>Figure 06</b> – Mumbai-RDS-SG</sub></p>
<p align="center"><img src="../screenshots/07_Mumbai_SecurityGroup_SG-0930-Details.png" width="880" alt="Mumbai security group details"><br><sub><b>Figure 07</b> – Mumbai security group details</sub></p>
<p align="center"><img src="../screenshots/08_Mumbai_SecurityGroup_Security-Groups-List.png" width="880" alt="Mumbai security groups list"><br><sub><b>Figure 08</b> – Mumbai security groups list</sub></p>
<p align="center"><img src="../screenshots/09_Singapore_SecurityGroup_SG-01f8-Details.png" width="880" alt="Singapore security group"><br><sub><b>Figure 09</b> – Singapore security group</sub></p>

## Phase 3 - Deploy the application on EC2
1. Launch `Mumbai-EC2-A` (t3.micro, public subnet in 1a) and `Mumbai-EC2-B` (second AZ).
2. Install and start Nginx, publish a custom `index.html` showing region, server name and status.

```bash
sudo dnf install -y nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx
```

<p align="center"><img src="../screenshots/10_Mumbai_EC2_EC2-A-Instance-Summary.png" width="880" alt="Mumbai-EC2-A instance summary"><br><sub><b>Figure 10</b> – Mumbai-EC2-A instance summary</sub></p>
<p align="center"><img src="../screenshots/11_Mumbai_EC2_EC2-B-Instance-Summary.png" width="880" alt="Mumbai-EC2-B instance summary"><br><sub><b>Figure 11</b> – Mumbai-EC2-B instance summary</sub></p>
<p align="center"><img src="../screenshots/16_Mumbai_EC2_Instances-List.png" width="880" alt="Both instances running in two AZs"><br><sub><b>Figure 16</b> – Both instances running in two AZs</sub></p>
<p align="center"><img src="../screenshots/12_Mumbai_EC2_EC2-B-Nginx-Setup-Terminal.png" width="880" alt="EC2-B page content and Nginx restart"><br><sub><b>Figure 12</b> – EC2-B page content and Nginx restart</sub></p>
<p align="center"><img src="../screenshots/14_Mumbai_EC2_EC2-B-Nginx-Status-Terminal.png" width="880" alt="Nginx service active on EC2-B"><br><sub><b>Figure 14</b> – Nginx service active on EC2-B</sub></p>
<p align="center"><img src="../screenshots/13_Mumbai_EC2_EC2-A-Web-Page-Running.png" width="880" alt="EC2-A web page - Mumbai Primary Region"><br><sub><b>Figure 13</b> – EC2-A web page - Mumbai Primary Region</sub></p>
<p align="center"><img src="../screenshots/15_Mumbai_EC2_EC2-B-Web-Page-Running.png" width="880" alt="EC2-B web page - second Availability Zone"><br><sub><b>Figure 15</b> – EC2-B web page - second Availability Zone</sub></p>

## Phase 4 - Attach and use EBS
1. Create/attach a 10 GiB EBS volume to EC2-A.
2. Format with XFS, mount on `/data`, write a test file.

```bash
lsblk
sudo mkfs -t xfs /dev/nvme1n1
sudo mkdir -p /data
sudo mount /dev/nvme1n1 /data
df -h
echo "AWS EBS storage verification" | sudo tee /data/ebs-test.txt
```

<p align="center"><img src="../screenshots/17_Mumbai_EBS_Volumes-List.png" width="880" alt="EBS volumes list"><br><sub><b>Figure 17</b> – EBS volumes list</sub></p>
<p align="center"><img src="../screenshots/18_Mumbai_EBS_Format-XFS-Terminal.png" width="880" alt="Format XFS and mount"><br><sub><b>Figure 18</b> – Format XFS and mount</sub></p>
<p align="center"><img src="../screenshots/19_Mumbai_EBS_Mount-Data-Test-File-Terminal.png" width="880" alt="/data mounted and test file created"><br><sub><b>Figure 19</b> – /data mounted and test file created</sub></p>

## Phase 5 - EFS shared storage on multiple EC2 instances
1. Create `Mumbai-Shared-EFS` (General Purpose, Elastic throughput, encrypted, automatic backups on, IA after 30 days / Archive after 90 days).
2. Create mount targets in both AZs and allow NFS (2049) from the web security group.
3. Mount on EC2-A and EC2-B, create files from one and read from the other.

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  <MOUNT_TARGET_IP_or_EFS_DNS>:/ /mnt/efs
sudo mkdir -p /mnt/efs/DR-Project
echo "created test1 file in ap-south-1a" | sudo tee /mnt/efs/DR-Project/test1.txt
```

<p align="center"><img src="../screenshots/20_Mumbai_EFS_Shared-EFS-Details.png" width="880" alt="EFS file system details"><br><sub><b>Figure 20</b> – EFS file system details</sub></p>
<p align="center"><img src="../screenshots/21_Mumbai_EFS_Network-Mount-Targets-1.png" width="880" alt="EFS network - mount targets"><br><sub><b>Figure 21</b> – EFS network - mount targets</sub></p>
<p align="center"><img src="../screenshots/22_Mumbai_EFS_Network-Mount-Targets-2.png" width="880" alt="EFS mount targets in both AZs"><br><sub><b>Figure 22</b> – EFS mount targets in both AZs</sub></p>
<p align="center"><img src="../screenshots/23_Mumbai_EFS_Mount-On-EC2-A-Terminal.png" width="880" alt="Mounting EFS on EC2-A"><br><sub><b>Figure 23</b> – Mounting EFS on EC2-A</sub></p>
<p align="center"><img src="../screenshots/24_Mumbai_EFS_Mounted-Filesystem-Terminal.png" width="880" alt="EFS mounted at /mnt/efs"><br><sub><b>Figure 24</b> – EFS mounted at /mnt/efs</sub></p>
<p align="center"><img src="../screenshots/25_Mumbai_EFS_Test-File-Created-EC2-A-Terminal.png" width="880" alt="File created on EC2-A"><br><sub><b>Figure 25</b> – File created on EC2-A</sub></p>
<p align="center"><img src="../screenshots/26_Mumbai_EFS_Verify-On-EC2-B-Terminal.png" width="880" alt="EFS mounted on EC2-B"><br><sub><b>Figure 26</b> – EFS mounted on EC2-B</sub></p>
<p align="center"><img src="../screenshots/27_Mumbai_EFS_Shared-Files-Verified-Terminal.png" width="880" alt="Same files visible from both instances"><br><sub><b>Figure 27</b> – Same files visible from both instances</sub></p>

## Phase 6 - S3 storage, versioning, replication, lifecycle
1. Create `atharv-dr-mumbai-2026` (Mumbai) and `atharv-dr-singapore-2026` (Singapore), enable **versioning** on both.
2. Upload business folders (`application/`, `employee-documents/`).
3. Create a replication rule Mumbai -> Singapore.
4. Create lifecycle rule `DR-S3-Document-Lifecycle` for current + noncurrent versions.

<p align="center"><img src="../screenshots/28_Mumbai_S3_Bucket-Objects.png" width="880" alt="Mumbai bucket objects"><br><sub><b>Figure 28</b> – Mumbai bucket objects</sub></p>
<p align="center"><img src="../screenshots/29_Mumbai_S3_Application-Folder.png" width="880" alt="application/ folder"><br><sub><b>Figure 29</b> – application/ folder</sub></p>
<p align="center"><img src="../screenshots/30_Mumbai_S3_Employee-Documents-Folder.png" width="880" alt="employee-documents/ folder"><br><sub><b>Figure 30</b> – employee-documents/ folder</sub></p>
<p align="center"><img src="../screenshots/31_Mumbai_S3_Bucket-Properties.png" width="880" alt="Bucket versioning in properties"><br><sub><b>Figure 31</b> – Bucket versioning in properties</sub></p>
<p align="center"><img src="../screenshots/32_Singapore_S3_Bucket-Objects.png" width="880" alt="Singapore bucket"><br><sub><b>Figure 32</b> – Singapore bucket</sub></p>
<p align="center"><img src="../screenshots/33_Singapore_S3_Bucket-Properties.png" width="880" alt="Singapore bucket properties"><br><sub><b>Figure 33</b> – Singapore bucket properties</sub></p>
<p align="center"><img src="../screenshots/34_Mumbai_S3_Replication-Rule-Details.png" width="880" alt="Replication rule details"><br><sub><b>Figure 34</b> – Replication rule details</sub></p>
<p align="center"><img src="../screenshots/35_Mumbai_S3_Replication-Rules.png" width="880" alt="Replication rules list"><br><sub><b>Figure 35</b> – Replication rules list</sub></p>
<p align="center"><img src="../screenshots/36_Singapore_S3_Replicated-Objects.png" width="880" alt="Objects replicated to Singapore"><br><sub><b>Figure 36</b> – Objects replicated to Singapore</sub></p>
<p align="center"><img src="../screenshots/58_Mumbai_S3_Lifecycle-Configuration.png" width="880" alt="S3 lifecycle rule DR-S3-Document-Lifecycle"><br><sub><b>Figure 58</b> – S3 lifecycle rule DR-S3-Document-Lifecycle</sub></p>

## Phase 7 - RDS MySQL
1. Create DB subnet group `dr-mumbai-rds-subnet-group` with the two private subnets.
2. Launch `dr-mumbai-mysql` (MySQL Community, db.t4g.micro, private, RDS security group).
3. From EC2 connect with the MySQL client and create sample data (`scripts/rds-sample-data.sql`).

```bash
mysql -h <RDS_ENDPOINT> -P 3306 -u admin -p
```

<p align="center"><img src="../screenshots/37_Mumbai_RDS_Subnet-Group.png" width="880" alt="DB subnet group"><br><sub><b>Figure 37</b> – DB subnet group</sub></p>
<p align="center"><img src="../screenshots/38_Mumbai_RDS_MySQL-Database-Details.png" width="880" alt="RDS instance created"><br><sub><b>Figure 38</b> – RDS instance created</sub></p>
<p align="center"><img src="../screenshots/39_Mumbai_RDS_MySQL-Database-Summary.png" width="880" alt="RDS instance with active connection"><br><sub><b>Figure 39</b> – RDS instance with active connection</sub></p>
<p align="center"><img src="../screenshots/40_Mumbai_RDS_Create-DB-Table-Terminal.png" width="880" alt="Create database, table and insert rows"><br><sub><b>Figure 40</b> – Create database, table and insert rows</sub></p>
<p align="center"><img src="../screenshots/41_Mumbai_RDS_Verify-Data-Terminal.png" width="880" alt="Query data from the database"><br><sub><b>Figure 41</b> – Query data from the database</sub></p>

## Phase 8 - EBS snapshots (manual + automated)
1. Take a manual snapshot `DR-Mumbai-EC2-A-EBS-Backup` of the data volume.
2. Create a Data Lifecycle Manager policy targeting tag `Name:Mumbai-EC2-A-EBS` with a daily schedule.

<p align="center"><img src="../screenshots/42_Mumbai_ResourceExplorer_Backup-Enabled-Resources.png" width="880" alt="Resource Explorer - backup-enabled resources"><br><sub><b>Figure 42</b> – Resource Explorer - backup-enabled resources</sub></p>
<p align="center"><img src="../screenshots/43_Mumbai_EBS_Snapshot.png" width="880" alt="Manual EBS snapshot completed"><br><sub><b>Figure 43</b> – Manual EBS snapshot completed</sub></p>
<p align="center"><img src="../screenshots/44_Mumbai_LifecycleManager_Policy-List.png" width="880" alt="DLM policy created"><br><sub><b>Figure 44</b> – DLM policy created</sub></p>
<p align="center"><img src="../screenshots/45_Mumbai_LifecycleManager_Policy-Details.png" width="880" alt="DLM policy details"><br><sub><b>Figure 45</b> – DLM policy details</sub></p>
<p align="center"><img src="../screenshots/46_Mumbai_LifecycleManager_Policy-Schedule.png" width="880" alt="DLM schedule"><br><sub><b>Figure 46</b> – DLM schedule</sub></p>

## Phase 9 - AMIs and cross-Region copy
Create `Mumbai-EC2-A-AMI`, then copy it to Singapore as `DR-Singapore-EC2-A-AMI`.

<p align="center"><img src="../screenshots/47_Mumbai_AMI_EC2-A-AMI.png" width="880" alt="AMI in Mumbai"><br><sub><b>Figure 47</b> – AMI in Mumbai</sub></p>
<p align="center"><img src="../screenshots/48_Singapore_AMI_DR-EC2-A-AMI-Copy.png" width="880" alt="AMI copied to Singapore"><br><sub><b>Figure 48</b> – AMI copied to Singapore</sub></p>

## Phase 10 - AWS Backup (vaults, plan, retention, cross-Region copy)
1. Create vaults `Mumbai-Backup-Vault` and `Singapore-DR-Vault`.
2. Create plan `DR-Mumbai-Daily-Backup-Plan`, rule `Daily-Backup-Plan`: daily, 09:00 AM Asia/Calcutta, start within 8 h, complete within 7 days, **retention 7 days**, copy to Singapore vault.
3. Assign resources and monitor jobs.
4. Take a manual RDS snapshot `dr-mumbai-mysql-manual-snapshot`.

<p align="center"><img src="../screenshots/49_Mumbai_Backup_Backup-Vault.png" width="880" alt="Mumbai backup vault"><br><sub><b>Figure 49</b> – Mumbai backup vault</sub></p>
<p align="center"><img src="../screenshots/50_Singapore_Backup_DR-Vault.png" width="880" alt="Singapore DR vault"><br><sub><b>Figure 50</b> – Singapore DR vault</sub></p>
<p align="center"><img src="../screenshots/51_Mumbai_Backup_Daily-Backup-Plan-Rule.png" width="880" alt="Backup rule - schedule and retention"><br><sub><b>Figure 51</b> – Backup rule - schedule and retention</sub></p>
<p align="center"><img src="../screenshots/52_Mumbai_Backup_Daily-Backup-Plan.png" width="880" alt="Backup plan"><br><sub><b>Figure 52</b> – Backup plan</sub></p>
<p align="center"><img src="../screenshots/53_Mumbai_Backup_Vault-Recovery-Points.png" width="880" alt="Vault recovery points"><br><sub><b>Figure 53</b> – Vault recovery points</sub></p>
<p align="center"><img src="../screenshots/54_Mumbai_Backup_Copy-Job.png" width="880" alt="Cross-Region copy job completed"><br><sub><b>Figure 54</b> – Cross-Region copy job completed</sub></p>
<p align="center"><img src="../screenshots/55_Singapore_Backup_Vault-EBS-Recovery-Point.png" width="880" alt="Recovery point in the Singapore vault"><br><sub><b>Figure 55</b> – Recovery point in the Singapore vault</sub></p>
<p align="center"><img src="../screenshots/56_Mumbai_RDS_Manual-Snapshot-1.png" width="880" alt="RDS manual snapshot"><br><sub><b>Figure 56</b> – RDS manual snapshot</sub></p>
<p align="center"><img src="../screenshots/57_Mumbai_RDS_Manual-Snapshot-2.png" width="880" alt="RDS snapshot details"><br><sub><b>Figure 57</b> – RDS snapshot details</sub></p>

## Phase 11 - Disaster recovery simulation
See the full procedure in [disaster-recovery-runbook.md](disaster-recovery-runbook.md).

<p align="center"><img src="../screenshots/59_Singapore_AMI_AMIs-List.png" width="880" alt="Copied AMI available in Singapore"><br><sub><b>Figure 59</b> – Copied AMI available in Singapore</sub></p>
<p align="center"><img src="../screenshots/60_DR-Test_EC2_Primary-Web-Page-Mumbai.png" width="880" alt="Primary application (Mumbai)"><br><sub><b>Figure 60</b> – Primary application (Mumbai)</sub></p>
<p align="center"><img src="../screenshots/62_Singapore_EC2_DR-Instance-Summary.png" width="880" alt="Recovered EC2 instance in Singapore"><br><sub><b>Figure 62</b> – Recovered EC2 instance in Singapore</sub></p>
<p align="center"><img src="../screenshots/61_DR-Test_EC2_DR-Web-Page-Singapore.png" width="880" alt="Application reachable on the Singapore IP"><br><sub><b>Figure 61</b> – Application reachable on the Singapore IP</sub></p>
<p align="center"><img src="../screenshots/68_Mumbai_Backup_Backup-Job-Completed.png" width="880" alt="Backup job completed (Mumbai)"><br><sub><b>Figure 68</b> – Backup job completed (Mumbai)</sub></p>
<p align="center"><img src="../screenshots/69_Singapore_Backup_Vault-Recovery-Point-Details.png" width="880" alt="Recovery point stored in Singapore vault"><br><sub><b>Figure 69</b> – Recovery point stored in Singapore vault</sub></p>
<p align="center"><img src="../screenshots/63_Mumbai_EBS_Restored-Volume-Details.png" width="880" alt="Restored EBS volume"><br><sub><b>Figure 63</b> – Restored EBS volume</sub></p>
<p align="center"><img src="../screenshots/64_Mumbai_EBS_Restored-Volume-Mount-Terminal.png" width="880" alt="Restored volume mounted and data verified"><br><sub><b>Figure 64</b> – Restored volume mounted and data verified</sub></p>
<p align="center"><img src="../screenshots/66_Singapore_RDS_Restored-Database-Details.png" width="880" alt="RDS restored in Singapore"><br><sub><b>Figure 66</b> – RDS restored in Singapore</sub></p>
<p align="center"><img src="../screenshots/65_Singapore_RDS_Connect-Restored-DB-Terminal.png" width="880" alt="Connect to restored DB and query data"><br><sub><b>Figure 65</b> – Connect to restored DB and query data</sub></p>
<p align="center"><img src="../screenshots/67_Mumbai_EFS_DR-Files-Verified-Terminal.png" width="880" alt="EFS data still available on EC2-A"><br><sub><b>Figure 67</b> – EFS data still available on EC2-A</sub></p>
