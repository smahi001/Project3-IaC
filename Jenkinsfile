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
        
        // Terraform Workspace Naming
        TF_WORKSPACE = "${params.ENVIRONMENT}"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform action to perform'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    stages {
        stage('Verify Credentials') {
            steps {
                script {
                    // Verify required credentials exist
                    withCredentials([
                        string(credentialsId: 'arm-access-key', variable: 'ARM_ACCESS_KEY'),
                        string(credentialsId: 'azure-sp-secret', variable: 'ARM_CLIENT_SECRET')
                    ]) {
                        echo "All required credentials are available"
                    }
                }
            }
        }
        
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
                        
                        // Select workspace
                        sh "terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}"
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
                        sh 'terraform plan -out=tfplan -var environment=${params.ENVIRONMENT}'
                        archiveArtifacts artifacts: 'tfplan'
                        
                        // Publish plan output
                        def planOutput = sh script: 'terraform show -no-color tfplan', returnStdout: true
                        echo "Terraform Plan Output:\n${planOutput}"
                    } catch (err) {
                        error("Planning phase failed: ${err}")
                    }
                }
            }
        }
        
        stage('Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.ENVIRONMENT == 'production' }
                }
            }
            steps {
                script {
                    def planOutput = sh script: 'terraform show -no-color tfplan', returnStdout: true
                    mail(
                        to: 'devops-team@yourcompany.com',
                        subject: "APPROVAL REQUIRED: Terraform Apply for ${params.ENVIRONMENT}",
                        body: "Review the plan output below and approve:\n\n${planOutput}"
                    )
                    
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: 'Approve production deployment?', 
                            ok: 'Deploy',
                            submitterParameter: 'approver'
                        )
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'production') {
                        def approver = input submitterParameter: 'approver'
                        echo "Production deployment approved by: ${approver}"
                    }
                    
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        input(
                            message: 'WARNING: This will DESTROY all infrastructure. Confirm?',
                            ok: 'Destroy'
                        )
                    }
                    sh 'terraform destroy -auto-approve -var environment=${params.ENVIRONMENT}'
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up sensitive files
                sh 'rm -f tfplan || true'
                sh 'rm -f terraform.tfvars || true'
                sh 'rm -f .terraform.lock.hcl || true'
                
                // Clean up workspace if not preserving for debugging
                if (currentBuild.result != 'FAILURE' || params.ENVIRONMENT == 'production') {
                    deleteDir()
                }
            }
        }
        success {
            script {
                echo "Pipeline succeeded! ${env.BUILD_URL}"
            }
        }
        failure {
            script {
                echo "Pipeline failed! Check logs at ${env.BUILD_URL}"
                
                // Enhanced error notification
                def errorMsg = "Pipeline failed in stage: ${currentBuild.result}\n"
                errorMsg += "Job: ${env.JOB_NAME}\n"
                errorMsg += "Build: ${env.BUILD_NUMBER}\n"
                errorMsg += "Environment: ${params.ENVIRONMENT}\n"
                errorMsg += "Action: ${params.ACTION}\n"
                errorMsg += "URL: ${env.BUILD_URL}"
                
                mail(
                    to: 'devops-team@yourcompany.com',
                    subject: "FAILED: ${env.JOB_NAME} - ${params.ENVIRONMENT}",
                    body: errorMsg
                )
            }
        }
    }
}
