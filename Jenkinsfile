pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
        // Add Azure CLI path if needed
        PATH = "/usr/bin:/usr/local/bin:${env.PATH}" 
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Dry-run or deploy')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
    }

    stages {
        stage('Setup Environment') {
            steps {
                script {
                    // Verify Azure CLI is installed
                    sh '''
                        if ! command -v az &> /dev/null; then
                            echo "Azure CLI not found, installing..."
                            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                        else
                            echo "Azure CLI is already installed"
                        fi
                        
                        az --version
                    '''
                }
            }
        }
        
        stage('Checkout Code') { 
            steps { 
                checkout scm 
            } 
        }
        
        stage('Terraform Init') {
            steps {
                sh """
                terraform init \
                    -backend-config="resource_group_name=tfstate-rg" \
                    -backend-config="storage_account_name=mytfstate123" \
                    -backend-config="container_name=tfstate" \
                    -backend-config="key=${params.ENVIRONMENT}.tfstate" \
                    -upgrade \
                    -reconfigure
                """
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan/Apply') {
            steps {
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    
                    // Login using service principal
                    withCredentials([usernamePassword(
                        credentialsId: 'azure-credentials',
                        usernameVariable: 'ARM_CLIENT_ID',
                        passwordVariable: 'ARM_CLIENT_SECRET'
                    )]) {
                        sh """
                        az login --service-principal \
                            -u ${env.ARM_CLIENT_ID} \
                            -p ${env.ARM_CLIENT_SECRET} \
                            --tenant ${env.ARM_TENANT_ID}
                        """
                        
                        if (params.ACTION == 'plan') {
                            sh """
                            terraform plan \
                                -var-file=${tfVarsFile} \
                                -input=false \
                                -out=tfplan-${params.ENVIRONMENT}
                            """
                            archiveArtifacts artifacts: "tfplan-${params.ENVIRONMENT}"
                        } 
                        else if (params.ACTION == 'apply') {
                            if (params.ENVIRONMENT == 'production') {
                                timeout(time: 30, unit: 'MINUTES') {
                                    input(message: "Approve PRODUCTION deployment?")
                                }
                            }
                            sh """
                            terraform apply \
                                -auto-approve \
                                -var-file=${tfVarsFile} \
                                -input=false
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always { 
            cleanWs() 
        }
        success { 
            echo "SUCCESS: ${params.ACTION} completed for ${params.ENVIRONMENT}"
        }
        failure { 
            echo "FAILED: Check logs at ${env.BUILD_URL}"
        }
    }
}
