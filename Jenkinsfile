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
                    // Determine environment from branch name
                    if (env.BRANCH_NAME == 'main') {
                        env.ENVIRONMENT = 'production'
                    } else if (env.BRANCH_NAME.startsWith('stage/')) {
                        env.ENVIRONMENT = 'staging'
                    } else {
                        env.ENVIRONMENT = 'dev'
                    }
                    echo "Running for environment: ${ENVIRONMENT} (Branch: ${BRANCH_NAME})"
                }
            }
        }

        stage('Azure Authentication') {
            steps {
                withCredentials([string(credentialsId: 'azure-sp-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    script {
                        // Verify Azure CLI access first
                        def loginStatus = sh(
                            script: """
                                az login --service-principal \
                                    -u ${ARM_CLIENT_ID} \
                                    -p ${ARM_CLIENT_SECRET} \
                                    --tenant ${ARM_TENANT_ID} && \
                                az account set --subscription ${ARM_SUBSCRIPTION_ID}
                            """,
                            returnStatus: true
                        )

                        if (loginStatus != 0) {
                            error("Azure login failed - check service principal permissions")
                        }

                        // Get storage key with proper error handling
                        try {
                            env.ARM_ACCESS_KEY = sh(
                                script: """
                                    az storage account keys list \
                                        -g ${TF_BACKEND_RESOURCE_GROUP} \
                                        -n ${TF_BACKEND_STORAGE_ACCOUNT} \
                                        --query '[0].value' -o tsv
                                """,
                                returnStdout: true
                            ).trim()
                        } catch (Exception e) {
                            error("Failed to get storage key. Ensure SP has 'Storage Account Key Operator' role.\nError: ${e.getMessage()}")
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
                            
                            if ! terraform workspace list | grep -q '${ENVIRONMENT}'; then
                                terraform workspace new ${ENVIRONMENT}
                            fi
                            terraform workspace select ${ENVIRONMENT}
                        """
                    } catch (Exception e) {
                        error("Terraform init failed: ${e.getMessage()}")
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                sh "terraform validate"
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
                        message: "Approve deployment to ${ENVIRONMENT} (Branch: ${BRANCH_NAME})?",
                        ok: 'Deploy'
                    )
                }
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
            echo "Pipeline completed. See details at: ${BUILD_URL}"
        }
        success {
            script {
                mail(
                    to: 'devops@example.com',
                    subject: "SUCCESS: ${JOB_NAME} [${ENVIRONMENT}]",
                    body: "Terraform ${params.ACTION} completed successfully\nBranch: ${BRANCH_NAME}\nBuild: ${BUILD_URL}"
                )
            }
        }
        failure {
            script {
                mail(
                    to: 'devops@example.com',
                    subject: "FAILED: ${JOB_NAME} [${ENVIRONMENT}]",
                    body: "Pipeline failed during ${params.ACTION}\nBranch: ${BRANCH_NAME}\nError: ${currentBuild.result}\nBuild: ${BUILD_URL}"
                )
            }
        }
    }
}
