pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"  // Recommended for CI/CD environments
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],  // Removed destroy option
            description: 'Terraform action to perform'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Deployment environment'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'terraform version'  // Verify Terraform is installed
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    try {
                        sh """
                        terraform init \
                            -backend-config="resource_group_name=tfstate-rg" \
                            -backend-config="storage_account_name=mytfstate123" \
                            -backend-config="container_name=tfstate" \
                            -backend-config="key=${params.ENVIRONMENT}.tfstate"
                        """
                    } catch (err) {
                        error("Terraform init failed: ${err}")
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform plan -out=tfplan'
                archiveArtifacts artifacts: 'tfplan'
            }
        }
        
        stage('Manual Approval') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Approve Terraform apply?', 
                        ok: 'Apply',
                        submitterParameter: 'approver'
                    )
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    def approver = input submitterParameter: 'approver'
                    echo "Approved by: ${approver}"
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            script {
                // Clean up sensitive files
                sh 'rm -f tfplan || true'
            }
        }
        success {
            slackSend(
                color: 'good',
                message: "SUCCESS: ${env.JOB_NAME} - ${params.ACTION} for ${params.ENVIRONMENT} - ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "FAILED: ${env.JOB_NAME} - ${params.ACTION} for ${params.ENVIRONMENT} - ${env.BUILD_URL}"
            )
            mail(
                to: 'devops-team@yourcompany.com',
                subject: "FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: "Check console output at ${env.BUILD_URL}"
            )
        }
    }
}
