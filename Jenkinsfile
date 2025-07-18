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
                script {
                    try {
                        sh '''
                        terraform init \
                            -backend-config="resource_group_name=tfstate-rg" \
                            -backend-config="storage_account_name=mytfstate123" \
                            -backend-config="container_name=tfstate" \
                            -backend-config="key=terraform.tfstate"
                        '''
                    } catch (err) {
                        echo "Init failed: ${err}"
                        currentBuild.result = 'FAILURE'
                        error('Terraform init failed')
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
                        echo "Validation failed: ${err}"
                        currentBuild.result = 'FAILURE'
                        error('Terraform validation failed')
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    try {
                        sh 'terraform plan -out=tfplan'
                        archiveArtifacts artifacts: 'tfplan'
                    } catch (err) {
                        echo "Plan failed: ${err}"
                        currentBuild.result = 'FAILURE'
                        error('Terraform plan failed')
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            script {
                // Add any cleanup steps here
            }
        }
        failure {
            mail to: 'team@yourdomain.com',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "Check console at ${env.BUILD_URL}"
        }
    }
}
