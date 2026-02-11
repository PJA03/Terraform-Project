
Welcome to my Final Project

# 1. Run this command first before everything else

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
./s3-script.ps1

# 2. Proceed to TF Plan/Apply

----------------------------------------------------------------------
For stress test of ASG Instances

# 1. Update repositories
sudo yum update -y

# 2. Install stress (Amazon Linux 2023 usually has it, if not, we use a fallback)
sudo yum install -y stress

# Stress 2 CPU cores for 600 seconds (10 minutes)
stress --cpu 2 --timeout 600
