pipeline {
    agent any

    environment {
        AWS_REGION = "sa-east-1"
    }

    stages {

        stage('Checkout Repo') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abhinav450718/redis-ha-infra3.o.git'
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
                    def master  = sh(script: "cd terraform && terraform output -raw redis_master_private_ip",  returnStdout: true).trim()
                    def replica = sh(script: "cd terraform && terraform output -raw redis_replica_private_ip", returnStdout: true).trim()
                    def bastion = sh(script: "cd terraform && terraform output -raw bastion_public_ip",       returnStdout: true).trim()

                    writeFile file: "ansible/inventory/hosts.ini", text: """
[redis_master]
${master}

[redis_replica]
${replica}

[bastion]
${bastion}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../terraform/redis_key.pem
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J ubuntu@${bastion}
"""
                }
            }
        }

        stage('Install Redis via Ansible') {
            steps {
                sh '''
                    cd ansible
                    ansible-galaxy install -r requirements.yml
                    ansible-playbook playbook.yml -i inventory/hosts.ini
                '''
            }
        }

        stage('Redis Test') {
            steps {
                sh '''
                MASTER=$(cd terraform && terraform output -raw redis_master_private_ip)
                REPLICA=$(cd terraform && terraform output -raw redis_replica_private_ip)
                BASTION=$(cd terraform && terraform output -raw bastion_public_ip)

                echo "Ping Master:"
                ssh -o StrictHostKeyChecking=no -i terraform/redis_key.pem -J ubuntu@$BASTION ubuntu@$MASTER 'redis-cli ping'

                echo "Ping Replica:"
                ssh -o StrictHostKeyChecking=no -i terraform/redis_key.pem -J ubuntu@$BASTION ubuntu@$REPLICA 'redis-cli ping'
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        failure {
            echo "Pipeline failed! Fix errors above."
        }
    }
}
