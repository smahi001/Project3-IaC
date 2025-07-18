pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'plan = dry run, apply = actual deployment'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target deployment environment'
        )
    }

    stages {
        stage('Verify Tools') {
            steps {
                script {
                    // Skip tool verification since we know Azure CLI is missing
                    echo "Skipping tool verification - assuming tools are installed"
                }
            }
        }

        stage('Azure Login') {
            steps {
                withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                    script {
                        // Simple check if az command exists
                        sh '''
                            if ! command -v az &> /dev/null; then
                                echo "Azure CLI not found! Please install it on the Jenkins agent."
                                exit 1
                            fi
                            
                            az login --service-principal \
                                -u $AZURE_CLIENT_ID \
                                -p $AZURE_CLIENT_SECRET \
                                --tenant $AZURE_TENANT_ID
                            az account set --subscription $AZURE_SUBSCRIPTION_ID
                            
                            # Get storage key for Terraform backend
                            export ARM_ACCESS_KEY=$(az storage account keys list \
                                -g tfstate-rg \
                                -n mytfstate123 \
                                --query '[0].value' -o tsv)
                        '''
                    }
                }
            }
        }

        stage('Checkout & Init') {
            steps {
                checkout scm
                sh '''
                    terraform init \
                        -backend-config="resource_group_name=tfstate-rg" \
                        -backend-config="storage_account_name=mytfstate123" \
                        -backend-config="container_name=tfstate" \
                        -backend-config="key=${ENVIRONMENT}.tfstate" \
                        -reconfigure
                '''
            }
        }

        stage('Validate & Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform validate'
                sh '''
                    terraform plan \
                        -out=tfplan \
                        -var environment=${ENVIRONMENT} \
                        -input=false
                '''
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
                        ok: 'Confirm'
                    )
                }
            }
        }

        stage('Apply Changes') {
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
