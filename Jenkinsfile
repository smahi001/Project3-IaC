pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh '''
                terraform init \
                  -backend-config="resource_group_name=tfstate-rg" \
                  -backend-config="storage_account_name=mytfstate123" \
                  -backend-config="container_name=tfstate" \
                  -backend-config="key=terraform.tfstate"
                '''
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
                archiveArtifacts artifacts: 'tfplan'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
