pipeline {
    agent any

    environment {
        ARM_CLIENT_ID       = credentials('ARM_CLIENT_ID')
        ARM_CLIENT_SECRET   = credentials('ARM_CLIENT_SECRET')
        ARM_SUBSCRIPTION_ID = credentials('ARM_SUBSCRIPTION_ID')
        ARM_TENANT_ID       = credentials('ARM_TENANT_ID')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh '''
                    terraform init \
                        -backend-config="resource_group_name=tfstate-rg" \
                        -backend-config="storage_account_name=mytfstate123"
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var-file="dev.tfvars"'
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: 'Approve apply?'
                sh 'terraform apply -auto-approve -var-file="dev.tfvars"'
            }
        }
    }
}
