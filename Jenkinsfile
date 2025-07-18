pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Dry-run or deploy')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
    }

    stages {
        stage('Checkout Code') { 
            steps { 
                checkout scm 
                // Print repository contents for debugging
                sh 'ls -la'
            } 
        }
        
        stage('Verify Files') {
            steps {
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    echo "Checking for variables file: ${tfVarsFile}"
                    
                    if (!fileExists(tfVarsFile)) {
                        error("ERROR: Variables file ${tfVarsFile} not found in repository!")
                    }
                    
                    // Also check for backend configuration
                    def backendConfig = [
                        "resource_group_name=tfstate-rg",
                        "storage_account_name=mytfstate123",
                        "container_name=tfstate",
                        "key=${params.ENVIRONMENT}.tfstate"
                    ]
                    
                    echo "Backend will be configured with: ${backendConfig}"
                }
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
                    -upgrade -reconfigure
                """
            }
        }
        
        stage('Terraform Plan/Apply') {
            steps {
                sh 'terraform validate'
                
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    
                    if (params.ACTION == 'plan') {
                        sh """
                        terraform plan \
                            -var-file=${tfVarsFile} \
                            -input=false \
                            -out=tfplan
                        """
                        // Archive the plan file
                        archiveArtifacts artifacts: 'tfplan', fingerprint: true
                    } 
                    else if (params.ACTION == 'apply') {
                        if (params.ENVIRONMENT == 'production') {
                            timeout(time: 30, unit: 'MINUTES') {
                                input(message: "Approve PRODUCTION deployment?")
                            }
                        }
                        sh """
                        terraform apply \
                            -auto-approve \
                            -var-file=${tfVarsFile} \
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
            echo "Pipeline completed for ${params.ENVIRONMENT} environment"
        }
        success { 
            echo "SUCCESS: ${params.ACTION} executed for ${params.ENVIRONMENT}" 
            // You could add Slack notifications here
        }
        failure { 
            echo "FAILED: Check logs at ${env.BUILD_URL}" 
            // You could add Slack/email notifications here
        }
    }
}
