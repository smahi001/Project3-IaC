pipeline {
    agent any

    environment {
        ARM_CLIENT_ID       = credentials('ARM_CLIENT_ID')
        ARM_CLIENT_SECRET   = credentials('ARM_CLIENT_SECRET')
        ARM_SUBSCRIPTION_ID = credentials('ARM_SUBSCRIPTION_ID')
        ARM_TENANT_ID       = credentials('ARM_TENANT_ID')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        // Dev Environment
        stage('Terraform Dev Init') {
            steps {
                sh '''
                    terraform init \
                        -backend-config="resource_group_name=tfstate-rg" \
                        -backend-config="storage_account_name=mytfstate123" \
                        -backend-config="container_name=tfstate" \
                        -backend-config="key=dev.tfstate" \
                        -upgrade -reconfigure
                '''
            }
        }
        stage('Terraform Dev Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Terraform Dev Plan') {
            steps {
                sh 'terraform plan -var-file="dev.tfvars" -input=false'
            }
        }
        stage('Terraform Dev Apply') {
            steps {
                input message: 'Approve apply for DEV?'
                sh 'terraform apply -auto-approve -var-file="dev.tfvars"'
            }
        }

        // Stage Environment
        stage('Terraform Stage Init') {
            steps {
                sh '''
                    terraform init \
                        -backend-config="resource_group_name=tfstate-rg" \
                        -backend-config="storage_account_name=mytfstate123" \
                        -backend-config="container_name=tfstate" \
                        -backend-config="key=stage.tfstate" \
                        -upgrade -reconfigure
                '''
            }
        }
        stage('Terraform Stage Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Terraform Stage Plan') {
            steps {
                sh 'terraform plan -var-file="stage.tfvars" -input=false'
            }
        }
        stage('Terraform Stage Apply') {
            steps {
                input message: 'Approve apply for STAGE?'
                sh 'terraform apply -auto-approve -var-file="stage.tfvars"'
            }
        }

        // Prod Environment
        stage('Terraform Prod Init') {
            steps {
                sh '''
                    terraform init \
                        -backend-config="resource_group_name=tfstate-rg" \
                        -backend-config="storage_account_name=mytfstate123" \
                        -backend-config="container_name=tfstate" \
                        -backend-config="key=prod.tfstate" \
                        -upgrade -reconfigure
                '''
            }
        }
        stage('Terraform Prod Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Terraform Prod Plan') {
            steps {
                sh 'terraform plan -var-file="prod.tfvars" -input=false'
            }
        }
        stage('Terraform Prod Apply') {
            steps {
                input message: 'Approve apply for PROD?'
                sh 'terraform apply -auto-approve -var-file="prod.tfvars"'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
