pipeline {
    agent any
    
    environment {
        // Azure Storage Backend Credentials
        ARM_ACCESS_KEY = credentials('arm-access-key')
        
        // Azure Service Principal Credentials using Jenkins-SP credential
        ARM_CLIENT_ID = credentials('Jenkins-SP')['clientId']
        ARM_CLIENT_SECRET = credentials('Jenkins-SP')['clientSecret']
        ARM_SUBSCRIPTION_ID = credentials('Jenkins-SP')['subscriptionId']
        ARM_TENANT_ID = credentials('Jenkins-SP')['tenantId']
        
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
        stage('Verify Credentials') {
            steps {
                script {
                    // Verify credentials exist before proceeding
                    withCredentials([
                        string(credentialsId: 'arm-access-key', variable: 'ARM_ACCESS_KEY'),
                        [$class: 'AzureServicePrincipal', credentialsId: 'Jenkins-SP']
                    ]) {
                        echo "All required credentials are available"
                    }
                }
            }
        }
        
        stage('Checkout SCM') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/smahi001/Project3-IaC.git'
                    ]]
                ])
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
                        
                        // Select or create workspace
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
