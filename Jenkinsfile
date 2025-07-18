pipeline {
    agent any

    // Remove the tools block since it's causing JDK installation issues
    // Terraform doesn't require Java, so we don't need JDK for this pipeline

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

    environment {
        TF_STATE_RG = "tfstate-rg"
        TF_STATE_SA = "mytfstate123"
        TF_STATE_CONTAINER = "tfstate"
    }

    stages {
        stage('Verify Tools') {
            steps {
                script {
                    echo "Checking required tools..."
                    sh '''
                        echo "Terraform version:"
                        terraform version || { echo "Terraform not found"; exit 1; }
                        echo "Azure CLI version:"
                        az --version || { echo "Azure CLI not found"; exit 1; }
                    '''
                }
            }
        }

        stage('Azure Login') {
            steps {
                withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                    script {
                        sh """
                            echo "Logging into Azure..."
                            az login --service-principal \
                                -u \$AZURE_CLIENT_ID \
                                -p \$AZURE_CLIENT_SECRET \
                                --tenant \$AZURE_TENANT_ID
                            az account set --subscription \$AZURE_SUBSCRIPTION_ID
                            
                            echo "Getting storage account key..."
                            export ARM_ACCESS_KEY=\$(az storage account keys list \
                                -g ${TF_STATE_RG} \
                                -n ${TF_STATE_SA} \
                                --query '[0].value' -o tsv)
                        """
                    }
                }
            }
        }

        stage('Checkout & Init') {
            steps {
                checkout scm
                sh """
                    terraform init \
                        -backend-config="resource_group_name=${TF_STATE_RG}" \
                        -backend-config="storage_account_name=${TF_STATE_SA}" \
                        -backend-config="container_name=${TF_STATE_CONTAINER}" \
                        -backend-config="key=${params.ENVIRONMENT}.tfstate" \
                        -reconfigure
                """
            }
        }

        stage('Validate & Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                sh 'terraform validate'
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
            script {
                // Clean up workspace inside a node context
                node {
                    cleanWs()
                }
            }
        }
        success {
            echo "SUCCESS: ${params.ACTION} completed for ${params.ENVIRONMENT}"
        }
        failure {
            echo "FAILED: Check logs at ${env.BUILD_URL}"
        }
    }
}
