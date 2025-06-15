pipeline {
    agent any
    
    environment {
        // Azure credentials - configure  in Jenkins credentials
        AZURE_CREDENTIALS = credentials('azure-service-principal')
        SSH_KEY = credentials('ssh-private-key')
        TERRAFORM_VERSION = '1.5.0'
    }
    
    stages {
        stage('Workspace Setup') {
            steps {
                echo 'Setting up workspace...'
                sh 'pwd && ls -la'
                sh 'ls -la /workspace'
            }
        }
        
        stage('Copy Files to Workspace') {
            steps {
                echo 'Copying project files from mounted volume...'
                sh '''
                    cp -r /workspace/* . || true
                    ls -la
                    echo "Files copied successfully"
                '''
            }
        }
        
        stage('Terraform Init') {
            steps {
                echo 'Initializing Terraform...'
                dir('terraform') {
                    script {
                        sh '''
                            export ARM_CLIENT_ID=${AZURE_CREDENTIALS_USR}
                            export ARM_CLIENT_SECRET=${AZURE_CREDENTIALS_PSW}
                            export ARM_TENANT_ID=${AZURE_CREDENTIALS_TENANT_ID:-"YOUR_TENANT_ID"}
                            export ARM_SUBSCRIPTION_ID=${AZURE_CREDENTIALS_SUBSCRIPTION_ID:-"YOUR_SUBSCRIPTION_ID"}
                            terraform init
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo 'Planning Terraform deployment...'
                dir('terraform') {
                    script {
                        sh '''
                            export ARM_CLIENT_ID=${AZURE_CREDENTIALS_USR}
                            export ARM_CLIENT_SECRET=${AZURE_CREDENTIALS_PSW}
                            export ARM_TENANT_ID=${AZURE_CREDENTIALS_TENANT_ID:-"YOUR_TENANT_ID"}
                            export ARM_SUBSCRIPTION_ID=${AZURE_CREDENTIALS_SUBSCRIPTION_ID:-"YOUR_SUBSCRIPTION_ID"}
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                echo 'Applying Terraform configuration...'
                dir('terraform') {
                    script {
                        sh '''
                            export ARM_CLIENT_ID=${AZURE_CREDENTIALS_USR}
                            export ARM_CLIENT_SECRET=${AZURE_CREDENTIALS_PSW}
                            export ARM_TENANT_ID=${AZURE_CREDENTIALS_TENANT_ID:-"YOUR_TENANT_ID"}
                            export ARM_SUBSCRIPTION_ID=${AZURE_CREDENTIALS_SUBSCRIPTION_ID:-"YOUR_SUBSCRIPTION_ID"}
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }
        
        stage('Wait for VM') {
            steps {
                echo 'Waiting for VM to be ready...'
                sleep(time: 60, unit: 'SECONDS')
            }
        }
        
        stage('Configure VM with Ansible') {
            steps {
                echo 'Configuring VM and deploying application with Ansible...'
                dir('ansible') {
                    script {
                        sh '''
                            # Wait for SSH to be available
                            VM_IP=$(terraform -chdir=../terraform output -raw public_ip_address)
                            echo "Waiting for SSH to be available on $VM_IP..."
                            
                            # Test SSH connectivity using a simple approach
                            timeout=300
                            while true; do
                                echo "Testing SSH connection to $VM_IP..."
                                if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes -i ${SSH_KEY} azureuser@$VM_IP 'echo "SSH connection successful"' 2>/dev/null; then
                                    echo "SSH is now available on $VM_IP"
                                    break
                                fi
                                sleep 10
                                timeout=$((timeout-10))
                                if [ $timeout -le 0 ]; then
                                    echo "Timeout waiting for SSH"
                                    exit 1
                                fi
                                echo "Still waiting for SSH... ($timeout seconds remaining)"
                            done
                            
                            # Run Ansible playbook
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            ansible-playbook -i inventory install_web.yml --private-key=${SSH_KEY} -v
                        '''
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying web application deployment...'
                script {
                    sh '''
                        VM_IP=$(terraform -chdir=terraform output -raw public_ip_address)
                        echo "Testing web application at http://$VM_IP"
                        
                        # Wait for web server to be ready
                        timeout=120
                        while ! curl -f http://$VM_IP > /dev/null 2>&1; do
                            sleep 5
                            timeout=$((timeout-5))
                            if [ $timeout -le 0 ]; then
                                echo "Timeout waiting for web server"
                                exit 1
                            fi
                        done
                        
                        echo "Web application is accessible!"
                        echo "URL: http://$VM_IP"
                        
                        # Show response content
                        curl -s http://$VM_IP | head -20
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
            script {
                try {
                    sh 'VM_IP=$(terraform -chdir=terraform output -raw public_ip_address 2>/dev/null) && echo "Application URL: http://$VM_IP" || echo "Could not get VM IP"'
                } catch (Exception e) {
                    echo "Could not retrieve VM IP: ${e.getMessage()}"
                }
            }
        }
        success {
            echo '✅ Pipeline completed successfully!'
            echo 'Your web application has been deployed to Azure!'
        }
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the logs above for error details.'
        }
        cleanup {
            echo 'Cleaning up workspace...'
        }
    }
}
