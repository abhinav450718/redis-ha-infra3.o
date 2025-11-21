pipeline {
    agent any

    stages {

        stage('Checkout Repo') {
            steps {
                git branch: 'main',
                    credentialsId: 'aws-creds',
                    url: 'https://github.com/abhinav450718/redis-ha-infra3.o.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
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
                    def master  = sh(script: "cd terraform && terraform output -raw redis_master_private_ip", returnStdout: true).trim()
                    def replica = sh(script: "cd terraform && terraform output -raw redis_replica_private_ip", returnStdout: true).trim()
                    def bastion = sh(script: "cd terraform && terraform output -raw bastion_public_ip", returnStdout: true).trim()

                    writeFile file: "ansible/inventory/hosts.ini", text: """
[redis_master]
${master} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/redis-demo-key.pem ansible_ssh_common_args='-o ProxyCommand="ssh -i ../terraform/redis-demo-key.pem ubuntu@${bastion} -W %h:%p"'

[redis_replica]
${replica} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/redis-demo-key.pem ansible_ssh_common_args='-o ProxyCommand="ssh -i ../terraform/redis-demo-key.pem ubuntu@${bastion} -W %h:%p"'
"""
                }
            }
        }

        stage('Install Redis via Ansible') {
            steps {
                sh '''
                    cd ansible
                    ansible-galaxy install -r requirements.yml
                    ansible-playbook site.yml -i inventory/hosts.ini --ssh-common-args="-o StrictHostKeyChecking=no"
                '''
            }
        }

        stage('Redis Test – Master & Replica') {
            steps {
                script {
                    def MASTER  = sh(script: "cd terraform && terraform output -raw redis_master_private_ip", returnStdout: true).trim()
                    def REPLICA = sh(script: "cd terraform && terraform output -raw redis_replica_private_ip", returnStdout: true).trim()
                    def BASTION = sh(script: "cd terraform && terraform output -raw bastion_public_ip", returnStdout: true).trim()

                    sh """
                        echo "Testing Redis Master..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                          -o ProxyCommand="ssh -i terraform/redis-demo-key.pem ubuntu@${BASTION} -W %h:%p" \
                          -i terraform/redis-demo-key.pem ubuntu@${MASTER} "redis-cli ping"

                        echo "Testing Redis Replica..."
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                          -o ProxyCommand="ssh -i terraform/redis-demo-key.pem ubuntu@${BASTION} -W %h:%p" \
                          -i terraform/redis-demo-key.pem ubuntu@${REPLICA} "redis-cli ping"
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline FAILED! Check errors above."
        }
        success {
            echo "✅ Pipeline executed successfully!"
        }
    }
}
