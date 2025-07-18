pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
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
                            -upgrade
                        """
                    } catch (err) {
                        error("Terraform init failed: ${err}")
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
                        error("Terraform validation failed: ${err}")
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
                        error("Terraform plan failed: ${err}")
                    }
                }
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
                sh 'rm -f tfplan || true'
            }
        }
        success {
            echo "Pipeline completed successfully for ${params.ENVIRONMENT}"
        }
        failure {
            mail(
                to: 'devops-team@yourcompany.com',
                subject: "FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: "Check console output at ${env.BUILD_URL}"
            )
        }
    }
}
