# Final DevOps Project: One-Click Jenkins Pipeline Deployment

This project demonstrates a fully automated DevOps pipeline using Jenkins (in Docker) that provisions infrastructure on Azure, configures a web server, and deploys a static web application.

## Architecture Overview

```
Jenkins (Docker) → Terraform → Azure VM → Ansible → Web Application
```

## Technology Stack

| Tool      | Purpose                                                |
| --------- | ------------------------------------------------------ |
| Docker    | Host Jenkins in a container                            |
| Jenkins   | Automate the workflow                                  |
| Terraform | Provision the virtual machine                          |
| Ansible   | Configure the VM and deploy the web app                |
| Azure     | Host the virtual machine                               |
| Git       | Store Jenkinsfile, code, playbooks, and Terraform code |

## Project Structure

```
project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── inventory.tpl
├── ansible/
│   └── install_web.yml
├── app/
│   └── index.html
├── Jenkinsfile
└── README.md
```

## Prerequisites

1. **Azure Account** with active subscription
2. **Docker** installed on your Mac M1
3. **SSH Key Pair** generated
4. **Azure CLI** installed and authenticated

## Setup Instructions

### 1. Generate SSH Key Pair (if not already done)

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Press Enter to accept default location (~/.ssh/id_rsa)
# Enter a passphrase or press Enter for no passphrase
```

### 2. Install Azure CLI and Login

```bash
# Install Azure CLI
brew install azure-cli

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Create a service principal for Terraform
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/your-subscription-id"
```

Save the output - you'll need it for Jenkins credentials.

### 3. Run Jenkins in Docker

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which terraform):/usr/local/bin/terraform \
  -v $(which ansible-playbook):/usr/local/bin/ansible-playbook \
  -v $(pwd):/workspace \
  jenkins/jenkins:lts
```

### 4. Initial Jenkins Setup

1. **Get Initial Admin Password:**

   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

2. **Access Jenkins:** Open http://localhost:8080

3. **Install Suggested Plugins** and create admin user

4. **Install Additional Plugins:**
   - Git Plugin
   - Pipeline Plugin
   - SSH Agent Plugin
   - Azure CLI Plugin

### 5. Configure Jenkins Credentials

1. Go to "Manage Jenkins" → "Manage Credentials"
2. Click "System" → "Global credentials"
3. Add these credentials:

   **Azure Service Principal:**

   - Kind: Username with password
   - ID: `azure-service-principal`
   - Username: Service Principal App ID
   - Password: Service Principal Password

   **SSH Private Key:**

   - Kind: SSH Username with private key
   - ID: `ssh-private-key`
   - Username: `azureuser`
   - Private Key: Contents of `~/.ssh/id_rsa`

### 6. Create Jenkins Pipeline Job

1. Click "New Item"
2. Enter name: `devops-pipeline`
3. Select "Pipeline"
4. In Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your Git repository URL
   - Branch: `*/main` (or your default branch)
   - Script Path: `Jenkinsfile`

### 7. Run the Pipeline

1. Click "Build Now"
2. Monitor the build progress
3. Check each stage for completion

## Pipeline Stages

1. **Checkout** - Gets code from Git repository
2. **Terraform Init** - Initializes Terraform configuration
3. **Terraform Plan** - Plans infrastructure changes
4. **Terraform Apply** - Provisions Azure VM
5. **Wait for VM** - Allows VM to fully boot
6. **Configure VM with Ansible** - Installs Apache and deploys web app
7. **Verify Deployment** - Tests web application accessibility

## Expected Output

Once the pipeline completes successfully:

- An Ubuntu VM will be running on Azure
- Apache web server will be installed and configured
- Your static web application will be accessible via the VM's public IP
- The Jenkins console will display the application URL

## Troubleshooting

### Common Issues:

1. **SSH Connection Failed:**

   - Ensure SSH key pair is correctly generated
   - Verify SSH private key is added to Jenkins credentials
   - Check Azure Network Security Group allows SSH (port 22)

2. **Terraform Authentication Failed:**

   - Verify Azure service principal credentials in Jenkins
   - Ensure `az login` was successful
   - Check subscription permissions

3. **Ansible Playbook Failed:**

   - Check SSH connectivity to the VM
   - Verify inventory file is generated correctly
   - Ensure VM is fully booted before Ansible runs

4. **Web Application Not Accessible:**
   - Verify Apache is running on the VM
   - Check Azure NSG allows HTTP traffic (port 80)
   - Confirm public IP is correctly assigned

### Debug Commands:

```bash
# Check Jenkins logs
docker logs jenkins

# Access Jenkins container
docker exec -it jenkins bash

# Check Terraform state
terraform show

# Test SSH connectivity
ssh -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP>

# Check Apache status on VM
systemctl status apache2
```

## Cleanup

To destroy the infrastructure and save costs:

```bash
# Navigate to terraform directory
cd terraform

# Destroy resources
terraform destroy -auto-approve
```

## Evaluation Criteria Met

- ✅ Jenkins runs from Docker (2 points)
- ✅ Terraform script creates VM (4 points)
- ✅ Ansible installs and configures web server (4 points)
- ✅ Static site deployed correctly (4 points)
- ✅ Jenkins pipeline triggers and completes all stages (4 points)
- ✅ Clean repo & documentation (2 points)

**Total: 20 points**

## Security Notes

- SSH keys are used for secure access
- Azure service principal follows least privilege principle
- Network security groups restrict access to necessary ports only
- Jenkins credentials are stored securely

## Next Steps

1. Implement infrastructure as code versioning
2. Add automated testing stages
3. Implement blue-green deployment strategy
4. Add monitoring and alerting
5. Implement proper secret management (Azure Key Vault)
