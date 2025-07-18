pipeline {
    agent any
    
    environment {
        AZURE_SUBSCRIPTION_ID = '0c3951d2-78d6-421a-8afc-9886db28d0eb'
        AZURE_TENANT_ID = '5e786868-9c77-4ab8-a348-aa45f70cf549'
        AZURE_CLIENT_ID = '63b7aeb4-36de-468e-a7df-526b8fda26e2'
        AZURE_CLIENT_SECRET = credentials('WqY8Q~w9xW4IjzK6ZOUDf41ZguBeCBdotnY5Babx') // Reference to the credential ID
        ARM_ACCESS_KEY = credentials('e0oyDzOhrYeLGorWV38ivxm49wAl5PUhKPNzKJSacTuZYiiE/9AvifvXvNkHRDTjVQfWGylwrO9X+AStXxqSUQ==') // For Terraform backend
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init -backend-config="resource_group_name=tfstate-rg" -backend-config="storage_account_name=<your-tfstate-storage-account-name>" -backend-config="container_name=tfstate" -backend-config="key=terraform.tfstate"'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
                archiveArtifacts artifacts: 'tfplan', fingerprint: true
            }
        }
        
        stage('Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Apply Terraform changes?', ok: 'Apply'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext body: '${DEFAULT_CONTENT}\n\nBuild URL: ${BUILD_URL}', 
                     subject: 'FAILED: Job ${JOB_NAME} - Build #${BUILD_NUMBER}', 
                     to: '08monisha1996@gmail.com'
        }
    }
}
