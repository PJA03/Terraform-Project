# ☁️ AWS 3-Tier Architecture with Terraform

This project deploys a highly available, scalable **3-Tier Web Architecture** on AWS using **Terraform**. It includes a public-facing Frontend, a private Backend, and a Bastion host for secure access.

## 🏗️ Architecture Overview
* **VPC:** Custom VPC with Public and Private subnets across 2 Availability Zones.
* **Compute:**
    * **Frontend:** Auto Scaling Group (ASG) with Application Load Balancer (ALB).
    * **Backend:** Auto Scaling Group (ASG) with Internal Load Balancer.
    * **Bastion Host:** For secure SSH access to private instances.
* **Security:** Tightly scoped Security Groups (ALB $\to$ Frontend $\to$ Backend).
* **Scaling:** Dynamic scaling policies based on CPU utilization.

## 🛠️ Prerequisites
* [Terraform](https://www.terraform.io/downloads) installed (`v1.0+`).
* [AWS CLI](https://aws.amazon.com/cli/) installed and configured with your credentials.
* PowerShell (for the S3 setup script).

---

## 🚀 Quick Start Guide

### 1. Setup Remote State (S3)
Run this script to create the S3 bucket for storing Terraform state.
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
./s3-script.ps1
```

### 2. Change directory to capstone folder then perform the standard TF commands
```
terraform init
terraform plan
terraform apply
```
---

## For Stress testing
### Update repositories
```powershell
sudo yum update -y
```

### Install stress tool
```powershell
sudo yum install -y stress
```

### Stress 2 CPU cores for 600 seconds
```powershell
stress --cpu 2 --timeout 600
```

## Unhealthy Target Group Testing
# If using Apache (Amazon Linux default)
```powershell
sudo systemctl stop httpd
```