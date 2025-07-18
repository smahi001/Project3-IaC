pipeline {
    agent any
    
    environment {
        // Azure Storage Backend Credentials
        ARM_ACCESS_KEY = credentials('arm-access-key')
        
        // Terraform Automation Settings
        TF_IN_AUTOMATION = "true"
        TF_WORKSPACE = "${params.ENVIRONMENT}"
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
        stage('Initialize') {
            steps {
                script {
                    // Get Azure Service Principal credentials
                    withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                        env.ARM_CLIENT_ID = "${env.AZURE_CLIENT_ID}"
                        env.ARM_CLIENT_SECRET = "${env.AZURE_CLIENT_SECRET}"
                        env.ARM_SUBSCRIPTION_ID = "${env.AZURE_SUBSCRIPTION_ID}"
                        env.ARM_TENANT_ID = "${env.AZURE_TENANT_ID}"
                    }
                    
                    echo "Using Service Principal with Client ID: ${env.ARM_CLIENT_ID}"
                }
            }
        }
        
        stage('Checkout SCM') {
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
                        
                        sh """
                        terraform workspace select ${params.ENVIRONMENT} || \
                        terraform workspace new ${params.ENVIRONMENT}
                        """
                    } catch (err) {
                        error("Terraform initialization failed: ${err.message}")
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
                        error("Configuration validation failed: ${err.message}")
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
                        sh """
                        terraform plan \
                            -out=tfplan \
                            -var environment=${params.ENVIRONMENT} \
                            -input=false
                        """
                        archiveArtifacts artifacts: 'tfplan'
                    } catch (err) {
                        error("Planning phase failed: ${err.message}")
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
                    
                    try {
                        sh 'terraform apply -auto-approve -input=false tfplan'
                    } catch (err) {
                        error("Apply failed: ${err.message}")
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        
        failure {
            script {
                echo "Pipeline failed! Check logs at ${env.BUILD_URL}"
            }
        }
    }
}
