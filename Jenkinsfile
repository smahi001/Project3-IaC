pipeline {
    agent any
    
    environment {
        // Storage account credentials
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
        
        // Service Principal credentials from your output
        ARM_SUBSCRIPTION_ID = "0c3951d2-78d6-421a-8afc-9886db28d0eb"
        ARM_CLIENT_ID = "63b7aeb4-36de-468e-a7df-526b8fda26e2"
        ARM_CLIENT_SECRET = credentials('azure-sp-secret')  // Store the password value here
        ARM_TENANT_ID = "5e786868-9c77-4ab8-a348-aa45f70cf549"
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
        
        stage('Terraform Plan/Apply') {
            steps {
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    
                    sh 'terraform validate'
                    
                    if (params.ACTION == 'plan') {
                        sh """
                        terraform plan \
                            -var-file=${tfVarsFile} \
                            -input=false \
                            -out=tfplan
                        """
                    } else if (params.ACTION == 'apply') {
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
            echo "SUCCESS: ${params.ACTION} for ${params.ENVIRONMENT}"
        }
        failure { 
            echo "FAILED: Check logs at ${env.BUILD_URL}"
        }
    }
}
