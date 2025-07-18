pipeline {
    agent any
    
    environment {
        // Azure Storage Backend Credentials only
        ARM_ACCESS_KEY = credentials('arm-access-key')
        
        // Terraform Automation Flag
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'plan = dry run, apply = actual deployment'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    stages {
        stage('Verify Tools') {
            steps {
                sh 'terraform version'
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
                    -reconfigure
                """
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                sh """
                terraform plan \
                    -out=tfplan \
                    -var environment=${params.ENVIRONMENT} \
                    -input=false
                """
                archiveArtifacts artifacts: 'tfplan'
            }
        }
        
        stage('Production Approval') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ENVIRONMENT == 'production' }
                }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Approve PRODUCTION deployment?', 
                        ok: 'Deploy'
                    )
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform apply -auto-approve -input=false tfplan'
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
