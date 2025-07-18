pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')  // Uses the credential you added
        TF_IN_AUTOMATION = "true"                      // Auto-mode for Terraform
    }

    parameters {
        choice(name: 'ACTION',     choices: ['plan', 'apply'], description: 'Dry-run or deploy')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Deploy to which environment?')
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
                sh """
                terraform validate && \
                terraform plan -out=tfplan -var environment=${params.ENVIRONMENT} -input=false
                """
                archiveArtifacts 'tfplan'
                
                // Auto-apply if ACTION=apply (non-production) or wait for approval (production)
                script {
                    if (params.ACTION == 'apply') {
                        if (params.ENVIRONMENT == 'production') {
                            timeout(time: 30, unit: 'MINUTES') {
                                input(message: "Approve PRODUCTION deployment?")
                            }
                        }
                        sh 'terraform apply -auto-approve -input=false tfplan'
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
