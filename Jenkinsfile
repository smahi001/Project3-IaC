pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
        
        // Add these authentication variables
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_CLIENT_SECRET = credentials('azure-client-secret')
        ARM_TENANT_ID = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Dry-run or deploy')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
    }

    stages {
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
