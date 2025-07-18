pipeline {
    agent any // The agent type will determine how commands are executed (sh for Unix-like, bat/powershell for Windows)

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform action to perform'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    stages {
        stage('Setup Environment and Authenticate') {
            steps {
                script {
                    echo "--- Verifying Tool Versions and Authenticating with Azure ---"

                    // Since your manual test confirms Azure CLI and Terraform are installed globally
                    // and are in the PATH on your Windows agent, we just need to verify them.
                    // Using 'bat' for Windows command prompt, or 'powershell' for PowerShell.
                    // 'sh' might work if Git Bash is the default shell for Jenkins on Windows,
                    // but 'bat' or 'powershell' are more explicit for Windows.
                    // Let's assume 'bat' for common commands, switch to 'powershell' if needed.
                    bat 'terraform version'
                    bat 'az --version'

                    // Use 'azureServicePrincipal' credential type to get all SP details
                    // 'Jenkins-SP' should be the ID of your Azure Service Principal credential in Jenkins
                    withCredentials([azureServicePrincipal('Jenkins-SP')]) {
                        // AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
                        // are automatically set as environment variables within this block.

                        echo "Authenticating with Azure CLI using Service Principal (Client ID: ${AZURE_CLIENT_ID})..."
                        // Use 'bat' for Windows commands. Note the double quotes and escaping for environment variables.
                        bat """
                            az login --service-principal ^
                                     --username %AZURE_CLIENT_ID% ^
                                     --password %AZURE_CLIENT_SECRET% ^
                                     --tenant %AZURE_TENANT_ID% ^
                                     --subscription %AZURE_SUBSCRIPTION_ID%
                        """
                        // ^ is the line continuation character in Windows Batch. %VAR% for environment variables.

                        echo "Azure CLI login successful. Verifying account:"
                        bat 'az account show'

                        // Retrieve Storage Account Key and set ARM_ACCESS_KEY for Terraform backend
                        // This uses Azure CLI, so it also needs to be a 'bat' command.
                        // The 'az' command is now assumed to be in the PATH.
                        // For setting environment variables that persist for subsequent 'bat' calls within the same 'script' block,
                        // you can use 'env.VAR_NAME = bat(returnStdout: true, script: 'command').trim()' or
                        // define them directly as shell env vars for 'sh' or 'bat'.
                        // For 'ARM_ACCESS_KEY', it's best set as an environment variable within the Jenkins step.
                        // Let's use Groovy to capture the output and set it.
                        def armAccessKey = bat(returnStdout: true, script: "az storage account keys list -g tfstate-rg -n mytfstate123 --query \"[0].value\" -o tsv").trim()
                        env.ARM_ACCESS_KEY = armAccessKey
                        echo "ARM_ACCESS_KEY set for Terraform backend authentication."
                    }
                }
            }
        }

        stage('Checkout SCM') {
            steps {
                echo "Checking out Git repository..."
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    try {
                        echo "Initializing Terraform..."
                        // Use 'bat' for Terraform commands on Windows
                        bat """
                            terraform init ^
                                -backend-config="resource_group_name=tfstate-rg" ^
                                -backend-config="storage_account_name=mytfstate123" ^
                                -backend-config="container_name=tfstate" ^
                                -backend-config="key=${params.ENVIRONMENT}/terraform.tfstate" ^
                                -upgrade ^
                                -reconfigure
                        """
                        echo "Managing Terraform workspace..."
                        // Note: For grep, you might need to use findstr on Windows if grep is not available via Git Bash.
                        // Assuming Git Bash (MINGW64) provides 'grep', 'bat' might still allow it.
                        // If 'grep' fails, replace with `cmd /c "terraform workspace list | findstr /C:"${params.ENVIRONMENT}"`
                        bat """
                            terraform workspace list | findstr /C:"${params.ENVIRONMENT}" > nul && (
                                echo Workspace exists. Selecting...
                                terraform workspace select ${params.ENVIRONMENT}
                            ) || (
                                echo Workspace does not exist. Creating new...
                                terraform workspace new ${params.ENVIRONMENT}
                            )
                        """
                    } catch (err) {
                        error("Terraform initialization failed: ${err.message}")
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                script {
                    try {
                        echo "Validating Terraform configuration..."
                        bat 'terraform validate'
                    } catch (err) {
                        error("Configuration validation failed: ${err.message}")
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' || params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                script {
                    try {
                        echo "Generating Terraform plan for ${params.ACTION} action in ${params.ENVIRONMENT} environment..."
                        def planCommand = "terraform plan -input=false"

                        if (params.ACTION == 'destroy') {
                            planCommand += " -destroy"
                        }
                        // Use -var-file for environment-specific variables
                        planCommand += " -out=tfplan -var-file=${params.ENVIRONMENT}.tfvars"

                        bat """
                            ${planCommand}
                        """
                        archiveArtifacts artifacts: 'tfplan', fingerprint: true
                    } catch (err) {
                        error("Planning phase failed: ${err.message}")
                    }
                }
            }
        }

        stage('Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
                    expression { params.ENVIRONMENT == 'production' || params.ENVIRONMENT == 'staging' }
                }
            }
            steps {
                script {
                    echo "Waiting for manual approval to ${params.ACTION} resources in ${params.ENVIRONMENT}..."
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: "Approve ${params.ACTION} for ${params.ENVIRONMENT} environment?",
                            ok: 'Proceed with Deployment/Destruction',
                            submitterParameter: 'approver'
                        )
                    }
                    echo "Approval granted by ${approver}."
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                script {
                    def finalCommand = "terraform apply -auto-approve -input=false tfplan"
                    if (params.ACTION == 'destroy') {
                        finalCommand = "terraform destroy -auto-approve -input=false"
                    }

                    try {
                        echo "Executing Terraform ${params.ACTION} for ${params.ENVIRONMENT} environment..."
                        bat "${finalCommand}"
                    } catch (err) {
                        error("Terraform ${params.ACTION} failed: ${err.message}")
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "Pipeline finished. Check logs at ${env.BUILD_URL}"
        }

        success {
            script {
                echo "Pipeline succeeded! Sending email notification."
                mail(
                    to: '08monisha1996@gmail.com', // <<--- REPLACE WITH YOUR ACTUAL EMAIL
                    subject: "Jenkins Pipeline SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: "The Jenkins pipeline '${env.JOB_NAME}' (Build #${env.BUILD_NUMBER}) for ${params.ENVIRONMENT} environment succeeded.\n\n" +
                          "Action performed: ${params.ACTION}\n" +
                          "Check logs at: ${env.BUILD_URL}"
                )
            }
        }

        failure {
            script {
                echo "Pipeline failed! Sending email notification."
                mail(
                    to: '08monisha1996@gmail.com', // <<--- REPLACE WITH YOUR ACTUAL EMAIL
                    subject: "Jenkins Pipeline FAILED: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: "The Jenkins pipeline '${env.JOB_NAME}' (Build #${env.BUILD_NUMBER}) for ${params.ENVIRONMENT} environment FAILED.\n\n" +
                          "Action attempted: ${params.ACTION}\n" +
                          "Check logs at: ${env.BUILD_URL}"
                )
            }
        }
    }
}
