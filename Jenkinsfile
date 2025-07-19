pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        ARM_CLIENT_ID = credentials('Jenkins-SP')
        ARM_CLIENT_SECRET = credentials('azure-sp-secret')
        ARM_TENANT_ID = "5e786868-9c77-4ab8-a348-aa45f70cf549"
        ARM_SUBSCRIPTION_ID = "0c3951d2-78d6-421a-8afc-9886db28d0eb"
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform action')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                terraform init \
                    -backend-config="resource_group_name=tfstate-rg" \
                    -backend-config="storage_account_name=mytfstate123" \
                    -backend-config="container_name=tfstate" \
                    -backend-config="key=${params.ENVIRONMENT}.tfstate" \
                    -upgrade \
                    -reconfigure
                """
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan/Apply') {
            steps {
                script {
                    def tfvarsFile = "${params.ENVIRONMENT}.tfvars"
                    if (params.ACTION == 'plan') {
                        sh """
                        terraform plan \
                            -var-file=${tfvarsFile} \
                            -input=false
                        """
                    } else if (params.ACTION == 'apply') {
                        if (params.ENVIRONMENT == 'production') {
                            timeout(time: 30, unit: 'MINUTES') {
                                input message: "Deploy to PRODUCTION?"
                            }
                        }
                        sh """
                        terraform apply \
                            -auto-approve \
                            -var-file=${tfvarsFile} \
                            -input=false
                        """
                    }
                }
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
