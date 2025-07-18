pipeline {
    agent any

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
        stage('Setup Environment') {
            steps {
                script {
                    // Verify tools are installed (skip installation if already present)
                    sh '''
                        echo "--- Tool Versions ---"
                        terraform version || echo "Terraform not found"
                        az version || echo "Azure CLI not found"
                    '''
                }
            }
        }

        stage('Azure Authentication') {
            steps {
                script {
                    withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                        sh """
                            echo "Authenticating with Azure..."
                            az login --service-principal \
                                -u ${AZURE_CLIENT_ID} \
                                -p ${AZURE_CLIENT_SECRET} \
                                --tenant ${AZURE_TENANT_ID}
                            
                            echo "Setting subscription..."
                            az account set --subscription ${AZURE_SUBSCRIPTION_ID}
                            
                            echo "Getting storage key..."
                            export ARM_ACCESS_KEY=\$(az storage account keys list \
                                -g tfstate-rg \
                                -n mytfstate123 \
                                --query '[0].value' -o tsv)
                        """
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
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
        }

        stage('Terraform Validate') {
            steps {
                script {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                script {
                    sh """
                        terraform plan \
                            -out=tfplan \
                            -var environment=${params.ENVIRONMENT} \
                            -input=false
                    """
                    archiveArtifacts artifacts: 'tfplan'
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
                            message: 'Approve PRODUCTION deployment?',
                            ok: 'Confirm'
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
                    sh 'terraform apply -auto-approve -input=false tfplan'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "SUCCESS: ${env.JOB_NAME} - ${params.ENVIRONMENT} - ${params.ACTION}"
        }
        failure {
            echo "FAILED: ${env.JOB_NAME} - ${params.ENVIRONMENT} - ${params.ACTION}"
            echo "Check logs at: ${env.BUILD_URL}"
        }
    }
}
