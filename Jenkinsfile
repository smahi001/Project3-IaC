pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Dry-run or deploy')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
    }

    stages {
        stage('Checkout Code') { 
            steps { checkout scm } 
        }
        
        stage('Terraform Init') {
            steps {
                sh """
                terraform init \
                    -backend-config="resource_group_name=tfstate-rg" \
                    -backend-config="storage_account_name=mytfstate123" \
                    -backend-config="container_name=tfstate" \
                    -backend-config="key=${params.ENVIRONMENT}.tfstate" \
                    -upgrade -reconfigure
                """
            }
        }
        
        stage('Terraform Plan/Apply') {
            steps {
                // First validate
                sh 'terraform validate'
                
                // Then plan or apply
                script {
                    if (params.ACTION == 'plan') {
                        sh """
                        terraform plan \
                            -var-file=${params.ENVIRONMENT}.tfvars \
                            -input=false
                        """
                    } else if (params.ACTION == 'apply') {
                        if (params.ENVIRONMENT == 'production') {
                            timeout(30) {
                                input(message: "Approve PRODUCTION deployment?")
                            }
                        }
                        sh """
                        terraform apply \
                            -auto-approve \
                            -var-file=${params.ENVIRONMENT}.tfvars \
                            -input=false
                        """
                    }
                }
            }
        }
    }

    post {
        always { cleanWs() }
        success { echo "SUCCESS: ${params.ACTION} for ${params.ENVIRONMENT}" }
        failure { echo "FAILED: Check logs at ${env.BUILD_URL}" }
    }
}
