pipeline {
    agent any
    
    environment {
        // Azure credentials - configure these in Jenkins credentials
        AZURE_CREDENTIALS = credentials('azure-service-principal')
        SSH_KEY = credentials('ssh-private-key')
        TERRAFORM_VERSION = '1.5.0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
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
                            export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
                            export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
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
                            export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
                            export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
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
                            export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
                            export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
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
                            timeout=300
                            while ! nc -z $VM_IP 22; do
                                sleep 5
                                timeout=$((timeout-5))
                                if [ $timeout -le 0 ]; then
                                    echo "Timeout waiting for SSH"
                                    exit 1
                                fi
                            done
                            
                            # Run Ansible playbook
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            ansible-playbook -i inventory install_web.yml --private-key=${SSH_KEY}
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
            // Uncomment the following line if you want to destroy resources after each run
            // sh 'terraform -chdir=terraform destroy -auto-approve || true'
        }
    }
}
