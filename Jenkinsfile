pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        AWS_REGION = "eu-west-2"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Install Terraform') {
            steps {
                sh '''
                  sudo apt-get update -y
                  sudo apt-get install -y wget unzip sshpass
                  
                  wget -O tf.zip https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
                  unzip -o tf.zip
                  sudo mv terraform /usr/local/bin/
                  terraform version
                '''
            }
        }

        stage('Install Ansible') {
            steps {
                sh '''
                  sudo apt-get update -y
                  sudo apt-get install -y python3 python3-pip
                  pip install ansible boto3 botocore
                  ansible --version

                  ansible-galaxy collection install amazon.aws
                  ansible-galaxy collection install community.general
                '''
            }
        }

        stage('Terraform Init + Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {

                    dir('terraform') {
                        sh 'terraform init -input=false'
                        sh 'terraform validate'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Ansible Deploy') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {

                    dir('ansible') {
                        sh 'ansible-inventory -i inventory.aws_ec2.yml --graph'
                        sh 'ansible-playbook site.yml'
                    }
                }
            }
        }

        // ---------------------------------------------------------
        // SHOW SSH COMMANDS + REDIS CLI COMMANDS + LIVE STATUS
        // ---------------------------------------------------------

        stage('Show SSH Commands & Redis Status') {
            steps {
                script {

                    def bastion = sh(returnStdout: true, script: "cd terraform && terraform output -raw bastion_public_ip").trim()
                    def master  = sh(returnStdout: true, script: "cd terraform && terraform output -raw redis_master_private_ip").trim()
                    def replica = sh(returnStdout: true, script: "cd terraform && terraform output -raw redis_replica_private_ip").trim()
                    def keypath = sh(returnStdout: true, script: "cd terraform && terraform output -raw private_key_path").trim()

                    echo "================ SSH COMMANDS ================"
                    echo "➡ Laptop → Bastion"
                    echo "ssh -i ${keypath} ubuntu@${bastion}"
                    echo "----------------------------------------------"
                    echo "➡ Bastion → Master"
                    echo "ssh -i ~/.ssh/redis-demo-key.pem ubuntu@${master}"
                    echo "----------------------------------------------"
                    echo "➡ Bastion → Replica"
                    echo "ssh -i ~/.ssh/redis-demo-key.pem ubuntu@${replica}"
                    echo "================================================"


                    echo "=============== REDIS CLI COMMANDS ================="
                    echo "➡ 1. Redis CLI from LOCAL → MASTER (via Bastion)"
                    echo "ssh -i ${keypath} -J ubuntu@${bastion} ubuntu@${master} \"redis-cli info replication\""
                    echo "----------------------------------------------------"

                    echo "➡ 2. Redis CLI from LOCAL → REPLICA (via Bastion)"
                    echo "ssh -i ${keypath} -J ubuntu@${bastion} ubuntu@${replica} \"redis-cli info replication\""
                    echo "----------------------------------------------------"

                    echo "➡ 3. Redis CLI from BASTION → MASTER"
                    echo "redis-cli -h ${master} -p 6379"
                    echo "----------------------------------------------------"

                    echo "➡ 4. Redis CLI from BASTION → REPLICA"
                    echo "redis-cli -h ${replica} -p 6379"
                    echo "===================================================="


                    echo "=============== LIVE REDIS STATUS ==================="

                    echo "➡ MASTER STATUS:"
                    sh """
                    ssh -o StrictHostKeyChecking=no -i ${keypath} ubuntu@${bastion} \\
                    "ssh -o StrictHostKeyChecking=no -i ~/.ssh/redis-demo-key.pem ubuntu@${master} 'redis-cli info replication'"
                    """

                    echo "➡ REPLICA STATUS:"
                    sh """
                    ssh -o StrictHostKeyChecking=no -i ${keypath} ubuntu@${bastion} \\
                    "ssh -o StrictHostKeyChecking=no -i ~/.ssh/redis-demo-key.pem ubuntu@${replica} 'redis-cli info replication'"
                    """

                    echo "====================================================="
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment Successful! Redis HA Cluster Verified!"
        }
        failure {
            echo "❌ Deployment Failed. Check Console Output!"
        }
    }
}

