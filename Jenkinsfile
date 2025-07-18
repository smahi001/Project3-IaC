pipeline {
    agent any
    
    environment {
        ARM_ACCESS_KEY = credentials('arm-access-key')
        TF_IN_AUTOMATION = "true"
        AZURE_CLI_ENABLE_LOGIN = "true"
    }

    parameters {
        choice(name: 'ACTION', 
               choices: ['plan', 'apply'], 
               description: 'Select plan for dry-run or apply to deploy')
               
        choice(name: 'ENVIRONMENT', 
               choices: ['dev', 'staging', 'production'], 
               description: 'Select target environment')
    }

    stages {
        stage('Checkout Code') { 
            steps { 
                checkout scm 
                // Debug: Show repository contents
                sh 'ls -la'
            } 
        }
        
        stage('Verify Files') {
            steps {
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    echo "Verifying configuration for ${params.ENVIRONMENT} environment"
                    
                    // Verify tfvars file exists
                    if (!fileExists(tfVarsFile)) {
                        error("ERROR: Variables file ${tfVarsFile} not found in repository!")
                    }
                    
                    // Verify backend configuration
                    def backendConfig = [
                        "resource_group_name=tfstate-rg",
                        "storage_account_name=mytfstate123",
                        "container_name=tfstate",
                        "key=${params.ENVIRONMENT}.tfstate"
                    ]
                    echo "Backend configuration: ${backendConfig}"
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
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan/Apply') {
            steps {
                script {
                    def tfVarsFile = "${params.ENVIRONMENT}.tfvars"
                    def planFile = "tfplan-${params.ENVIRONMENT}"
                    
                    if (params.ACTION == 'plan') {
                        sh """
                        terraform plan \
                            -var="environment=${params.ENVIRONMENT}" \
                            -var-file=${tfVarsFile} \
                            -input=false \
                            -out=${planFile}
                        """
                        // Save plan file for potential apply
                        archiveArtifacts artifacts: "${planFile}", fingerprint: true
                        
                        // Generate plan output as JSON for parsing if needed
                        sh """
                        terraform show -json ${planFile} > ${planFile}.json
                        """
                        archiveArtifacts artifacts: "${planFile}.json"
                        
                    } else if (params.ACTION == 'apply') {
                        // Additional approval for production
                        if (params.ENVIRONMENT == 'production') {
                            timeout(time: 30, unit: 'MINUTES') {
                                input(
                                    message: "PRODUCTION DEPLOYMENT APPROVAL REQUIRED", 
                                    ok: "Deploy to Production",
                                    parameters: [
                                        text(
                                            name: 'REASON', 
                                            description: 'Reason for deployment', 
                                            defaultValue: 'Scheduled deployment'
                                        )
                                    ]
                                )
                            }
                        }
                        
                        // For apply, use the plan file if available
                        def applyCmd = """
                        terraform apply \
                            -auto-approve \
                            -var="environment=${params.ENVIRONMENT}" \
                            -var-file=${tfVarsFile} \
                            -input=false
                        """
                        
                        // If plan file exists from previous step, use it
                        if (fileExists("${planFile}")) {
                            applyCmd = "terraform apply -auto-approve ${planFile}"
                        }
                        
                        sh applyCmd
                    }
                }
            }
        }
        
        stage('Output Results') {
            steps {
                script {
                    // Get outputs and save them
                    sh 'terraform output -json > terraform_output.json'
                    archiveArtifacts artifacts: 'terraform_output.json'
                    
                    // Parse and display important outputs
                    def outputs = readJSON file: 'terraform_output.json'
                    echo "Deployment completed. Key outputs:"
                    outputs.each { key, value -> 
                        echo "${key}: ${value.value}"
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace but keep important files
            cleanWs(
                cleanWhenAborted: true,
                cleanWhenFailure: true,
                cleanWhenNotBuilt: true,
                cleanWhenSuccess: true,
                deleteDirs: true,
                patterns: [
                    [pattern: '.terraform/**', type: 'INCLUDE'],
                    [pattern: '.terraform.lock.hcl', type: 'EXCLUDE'],
                    [pattern: '**/*.tfstate', type: 'EXCLUDE'],
                    [pattern: '**/*.tfvars', type: 'EXCLUDE']
                ]
            )
            
            // Send notification
            script {
                def subject = "${currentBuild.result ?: 'SUCCESS'}: Job '${env.JOB_NAME}' (${env.BUILD_NUMBER})"
                def details = """
                Environment: ${params.ENVIRONMENT}
                Action: ${params.ACTION}
                Build URL: ${env.BUILD_URL}
                Duration: ${currentBuild.durationString}
                """
                
                echo subject
                echo details
                
                // Add Slack/Email notification here if configured
                // slackSend channel: '#devops', message: "${subject}\n${details}"
            }
        }
        
        success {
            echo "SUCCESS: Terraform ${params.ACTION} completed for ${params.ENVIRONMENT} environment"
        }
        
        failure {
            echo "FAILURE: Check full logs at ${env.BUILD_URL}console"
            // Additional failure handling can be added here
        }
        
        unstable {
            echo "UNSTABLE: The build was marked as unstable"
        }
    }
}
