pipeline {
    agent any

    environment {
        AWS_REGION = "eu-west-2"
    }

    stages {

        stage('Checkout Repo') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abhinav450718/redis-ha-infra3.o.git'
            }
        }

        stage('Install Terraform') {
            steps {
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y wget unzip

                    wget -O tf.zip https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
                    unzip -o tf.zip
                    sudo mv terraform /usr/local/bin/

                    terraform version
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Generate Inventory') {
            steps {
                script {
                    def master_ip  = sh(script: "cd terraform && terraform output -raw redis_master_private_ip",  returnStdout: true).trim()
                    def replica_ip = sh(script: "cd terraform && terraform output -raw redis_replica_private_ip", returnStdout: true).trim()
                    def bastion_ip = sh(script: "cd terraform && terraform output -raw bastion_public_ip",       returnStdout: true).trim()

                    writeFile file: "ansible/inventory/hosts.ini", text: """
[redis_master]
${master_ip}

[redis_replica]
${replica_ip}

[bastion]
${bastion_ip}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../terraform/redis-demo-key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J ubuntu@${bastion_ip}
"""
                }
            }
        }

        stage('Install Ansible') {
            steps {
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y python3 python3-pip
                    pip install ansible boto3 botocore
                '''
            }
        }

        stage('Install Redis via Ansible') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        cd ansible
                        ansible-galaxy install -r requirements.yml
                        ansible-playbook site.yml -i inventory/hosts.ini
                    '''
                }
            }
        }

        stage('Redis Test') {
            steps {
                sh '''
                    MASTER_IP=$(cd terraform && terraform output -raw redis_master_private_ip)
                    REPLICA_IP=$(cd terraform && terraform output -raw redis_replica_private_ip)
                    BASTION_IP=$(cd terraform && terraform output -raw bastion_public_ip)

                    echo "Testing Redis Master..."
                    ssh -o StrictHostKeyChecking=no -i terraform/redis-demo-key.pem -J ubuntu@$BASTION_IP ubuntu@$MASTER_IP 'redis-cli info replication'

                    echo "Testing Redis Replica..."
                    ssh -o StrictHostKeyChecking=no -i terraform/redis-demo-key.pem -J ubuntu@$BASTION_IP ubuntu@$REPLICA_IP 'redis-cli info replication'
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Check full logs above."
        }
        success {
            echo "🎉 Redis HA Deployment SUCCESS!"
        }
        failure {
            echo "❌ Deployment FAILED! Fix errors shown above."
        }
    }
}
