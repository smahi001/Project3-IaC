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
        stage('Setup and Authenticate') {
            steps {
                script {
                    // Install tools if needed (remove if already on agent)
                    sh '''
                        echo "Checking tool versions:"
                        terraform version || echo "Terraform not installed"
                        az version || echo "Azure CLI not installed"
                    '''

                    // Authenticate with Azure using Service Principal
                    withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                        sh """
                            echo "Logging into Azure CLI..."
                            az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
                            az account set --subscription ${AZURE_SUBSCRIPTION_ID}
                            
                            echo "Getting storage account key..."
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
                            message: 'Approve production deployment?', 
                            ok: 'Deploy'
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
        failure {
            echo "Pipeline failed! Check logs at ${env.BUILD_URL}"
        }
    }
}
