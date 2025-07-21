pipeline {
    agent any

    options {
        skipDefaultCheckout(true)  // We'll handle checkout manually
        disableConcurrentBuilds()   // Prevent parallel runs on same branch
        timeout(time: 1, unit: 'HOURS')
    }

    environment {
        // Static Azure config (non-sensitive)
        ARM_SUBSCRIPTION_ID = "0c3951d2-78d6-421a-8afc-9886db28d0eb"
        ARM_CLIENT_ID = "63b7aeb4-36de-468e-a7df-526b8fda26e2"
        ARM_TENANT_ID = "5e786868-9c77-4ab8-a348-aa45f70cf549"

        // Terraform backend (shared across branches)
        TF_BACKEND_RESOURCE_GROUP = "tfstate-rg"
        TF_BACKEND_STORAGE_ACCOUNT = "mytfstate123"
        TF_BACKEND_CONTAINER = "tfstate"
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
                    // Auto-detect environment from branch name
                    env.ENVIRONMENT = detectEnvironmentFromBranch(BRANCH_NAME)
                    echo "Running for environment: ${ENVIRONMENT}"

                    checkout scm  // Checkout the specific branch
                }
            }
        }

        stage('Azure Authentication') {
            steps {
                withCredentials([string(credentialsId: 'azure-sp-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    sh """
                        az login --service-principal \
                            --username "$ARM_CLIENT_ID" \
                            --password "$ARM_CLIENT_SECRET" \
                            --tenant "$ARM_TENANT_ID"
                        
                        export ARM_ACCESS_KEY=\$(az storage account keys list \
                            -g "$TF_BACKEND_RESOURCE_GROUP" \
                            -n "$TF_BACKEND_STORAGE_ACCOUNT" \
                            --query '[0].value' -o tsv)
                    """
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                    terraform init \
                        -backend-config="resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
                        -backend-config="storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
                        -backend-config="container_name=$TF_BACKEND_CONTAINER" \
                        -backend-config="key=${ENVIRONMENT}-${BRANCH_NAME}.tfstate"
                    
                    terraform workspace select ${ENVIRONMENT}-${BRANCH_NAME} || \
                    terraform workspace new ${ENVIRONMENT}-${BRANCH_NAME}
                """
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' }
            }
            steps {
                sh """
                    terraform plan \
                        -var-file="${ENVIRONMENT}.tfvars" \
                        -out="${WORKSPACE}/tfplan-${BUILD_NUMBER}"
                """
                archiveArtifacts "tfplan-${BUILD_NUMBER}"
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
                        message: "Approve ${BRANCH_NAME} deployment to ${ENVIRONMENT}?",
                        submitterParameter: 'approver'
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
                sh "terraform apply -auto-approve -var-file=${ENVIRONMENT}.tfvars"
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "Build ${BUILD_NUMBER} completed. Details: ${BUILD_URL}"
        }
        success {
            emailext(
                subject: "SUCCESS: ${JOB_NAME} [${BRANCH_NAME}] - ${params.ACTION}",
                body: "Completed ${params.ACTION} for ${ENVIRONMENT}\nBranch: ${BRANCH_NAME}\nBuild: ${BUILD_URL}",
                to: 'devops@example.com'
            )
        }
        failure {
            emailext(
                subject: "FAILED: ${JOB_NAME} [${BRANCH_NAME}] - ${params.ACTION}",
                body: "Failed ${params.ACTION} for ${ENVIRONMENT}\nBranch: ${BRANCH_NAME}\nBuild: ${BUILD_URL}",
                to: 'devops@example.com'
            )
        }
    }
}

// Helper function to map branches to environments
def detectEnvironmentFromBranch(String branchName) {
    switch(branchName) {
        case ~/^dev-.*/:       return 'dev'
        case ~/^staging-.*/:   return 'staging'
        case ~/^main|prod-.*/: return 'production'
        default:               return 'dev'  // Fallback for feature branches
    }
}
