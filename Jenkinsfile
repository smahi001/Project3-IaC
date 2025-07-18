pipeline {
    agent any
    
    environment {
        // Azure Storage Backend Credentials
        ARM_ACCESS_KEY = credentials('arm-access-key')
        
        // Azure Service Principal Credentials
        ARM_CLIENT_ID = '63b7aeb4-36de-468e-a7df-526b8fda26e2'
        ARM_CLIENT_SECRET = credentials('azure-sp-secret')
        ARM_SUBSCRIPTION_ID = '0c3951d2-78d6-421a-8afc-9886db28d0eb'
        ARM_TENANT_ID = '5e786868-9c77-4ab8-a348-aa45f70cf549'
        
        // Terraform Automation Flag
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Select Terraform action to perform'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                sh 'terraform version'
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
                            -backend-config="key=${params.ENVIRONMENT}.tfstate" \
                            -upgrade \
                            -reconfigure
                        """
                    } catch (err) {
                        error("Terraform initialization failed: ${err}")
                    }
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                script {
                    try {
                        sh 'terraform validate'
                    } catch (err) {
                        error("Configuration validation failed: ${err}")
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                script {
                    try {
                        sh 'terraform plan -out=tfplan'
                        archiveArtifacts artifacts: 'tfplan'
                    } catch (err) {
                        error("Planning phase failed: ${err}")
                    }
                }
            }
        }
        
        stage('Approval Gate') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Approve production deployment?', 
                        ok: 'Deploy',
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
            script {
                // Clean up workspace
                cleanWs()
                
                // Remove sensitive files
                sh 'rm -f tfplan || true'
                sh 'rm -f terraform.tfvars || true'
            }
        }
        success {
            echo "Pipeline executed successfully for ${params.ENVIRONMENT} environment"
        }
        failure {
            script {
                echo "Pipeline failed! Check logs at ${env.BUILD_URL}"
                
                // Basic notification if email is configured
                try {
                    mail(
                        to: 'devops-team@yourcompany.com',
                        subject: "FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                        body: "Check console output at ${env.BUILD_URL}",
                        replyTo: 'no-reply@yourcompany.com'
                    )
                } catch (err) {
                    echo "Failed to send email notification: ${err}"
                }
            }
        }
    }
}
