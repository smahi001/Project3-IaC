pipeline {
    agent any

    options {
        skipDefaultCheckout(false)
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
    }

    environment {
        // Azure Configuration
        ARM_SUBSCRIPTION_ID = "0c3951d2-78d6-421a-8afc-9886db28d0eb"
        ARM_CLIENT_ID = "63b7aeb4-36de-468e-a7df-526b8fda26e2"
        ARM_TENANT_ID = "5e786868-9c77-4ab8-a348-aa45f70cf549"
        
        // Terraform Backend
        TF_BACKEND_RESOURCE_GROUP = "tfstate-rg"
        TF_BACKEND_STORAGE_ACCOUNT = "mytfstate123"
        TF_BACKEND_CONTAINER = "tfstate"
        TF_IN_AUTOMATION = "true"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Select Terraform action'
        )
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Enhanced branch to environment mapping
                    env.ENVIRONMENT = determineEnvironment(env.BRANCH_NAME)
                    echo "Environment: ${ENVIRONMENT}"
                    echo "Branch: ${BRANCH_NAME}"
                    checkout scm
                }
            }
        }

        stage('Azure Authentication') {
            steps {
                withCredentials([string(credentialsId: 'Jenkins-SP', variable: 'ARM_CLIENT_SECRET')]) {
                    script {
                        // Secure authentication with error handling
                        try {
                            // 1. Azure Login
                            sh """
                                az login --service-principal \
                                    -u ${ARM_CLIENT_ID} \
                                    -p '${ARM_CLIENT_SECRET}' \
                                    --tenant ${ARM_TENANT_ID}
                                az account set --subscription ${ARM_SUBSCRIPTION_ID}
                            """
                            
                            // 2. Verify permissions
                            def roles = sh(
                                script: "az role assignment list --assignee ${ARM_CLIENT_ID} --query [].roleDefinitionName -o tsv",
                                returnStdout: true
                            ).trim()
                            
                            if (!roles.contains('Contributor') || !roles.contains('Storage Account Key Operator Service Role')) {
                                error("Service Principal missing required roles. Needs both 'Contributor' and 'Storage Account Key Operator Service Role'")
                            }

                            // 3. Get storage key
                            env.ARM_ACCESS_KEY = sh(
                                script: """
                                    az storage account keys list \
                                        -g ${TF_BACKEND_RESOURCE_GROUP} \
                                        -n ${TF_BACKEND_STORAGE_ACCOUNT} \
                                        --query '[0].value' -o tsv
                                """,
                                returnStdout: true
                            ).trim()
                            
                            if (!env.ARM_ACCESS_KEY) {
                                error("Empty storage key received. Verify SP permissions on storage account.")
                            }
                        } catch (Exception e) {
                            error("Azure authentication failed: ${e.getMessage()}")
                        }
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    try {
                        sh """
                            terraform init \
                                -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
                                -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
                                -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
                                -backend-config="key=${ENVIRONMENT}.tfstate" \
                                -backend-config="access_key=${ARM_ACCESS_KEY}" \
                                -reconfigure
                            
                            terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}
                        """
                    } catch (Exception e) {
                        error("Terraform init failed: ${e.getMessage()}\nVerify backend configuration and permissions.")
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh "terraform validate -no-color"
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' }
            }
            steps {
                script {
                    try {
                        def planFile = "tfplan-${BUILD_NUMBER}"
                        sh """
                            terraform plan \
                                -input=false \
                                -var-file="${ENVIRONMENT}.tfvars" \
                                -out="${planFile}"
                        """
                        archiveArtifacts artifacts: "${planFile}", fingerprint: true
                    } catch (Exception e) {
                        error("Terraform plan failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { ENVIRONMENT == 'production' || ENVIRONMENT == 'staging' }
                }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: "Approve ${params.ACTION} for ${ENVIRONMENT} environment?",
                        submitterParameter: 'approver',
                        ok: 'Deploy'
                    )
                }
                echo "Approved by: ${approver}"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    try {
                        sh """
                            terraform apply \
                                -input=false \
                                -auto-approve \
                                -var-file="${ENVIRONMENT}.tfvars"
                        """
                    } catch (Exception e) {
                        error("Terraform apply failed: ${e.getMessage()}")
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "Pipeline completed. Details: ${BUILD_URL}"
        }
        success {
            script {
                if (params.ACTION == 'apply') {
                    emailext(
                        subject: "SUCCESS: ${JOB_NAME} [${ENVIRONMENT}]",
                        body: """
                        Terraform deployment completed
                        Environment: ${ENVIRONMENT}
                        Branch: ${BRANCH_NAME}
                        Action: ${params.ACTION}
                        Build: ${BUILD_URL}
                        """,
                        to: 'devops@example.com',
                        mimeType: 'text/plain'
                    )
                }
            }
        }
        failure {
            emailext(
                subject: "FAILED: ${JOB_NAME} [${ENVIRONMENT}]",
                body: """
                Pipeline failed!
                Environment: ${ENVIRONMENT}
                Branch: ${BRANCH_NAME}
                Action: ${params.ACTION}
                Error: ${currentBuild.result}
                Build: ${BUILD_URL}
                """,
                to: 'devops@example.com',
                mimeType: 'text/plain'
            )
        }
    }
}

// Helper function for environment mapping
def determineEnvironment(branchName) {
    switch(branchName) {
        case 'main': return 'production'
        case ~/^stage\/.*/: return 'staging'
        default: return 'dev'
    }
}
