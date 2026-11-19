#!/bin/bash
# Install Nginx and publish a status page (Amazon Linux 2023)
set -e
sudo dnf install -y nginx
sudo systemctl enable --now nginx
sudo tee /usr/share/nginx/html/index.html >/dev/null <<'EOF'
<html><body style="font-family:Arial;text-align:center">
<h1>AWS Disaster Recovery Project</h1>
<h2>Mumbai Primary Region</h2>
<h3>EC2-A Application Server</h3>
<p style="color:green">Application Status: RUNNING</p>
<p>Region: ap-south-1</p>
<p>Project: Backup and Business Continuity</p>
<p>Application: Nginx Web Server</p>
</body></html>
EOF
sudo systemctl restart nginx
