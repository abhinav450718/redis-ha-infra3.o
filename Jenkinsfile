pipeline {
    agent any

    environment {
        AWS_REGION = "eu-west-1"
    }

    stages {

        /* ---------------------------
           CHECKOUT REPOSITORY
        --------------------------- */
        stage('Checkout Repo') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abhinav450718/redis-ha-infra3.o.git'
            }
        }

        /* ---------------------------
           TERRAFORM APPLY
        --------------------------- */
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

        /* ---------------------------
           GENERATE ANSIBLE INVENTORY
        --------------------------- */
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

                    sh "echo '===== GENERATED INVENTORY ====='"
                    sh "cat ansible/inventory/hosts.ini"
                }
            }
        }

        /* ---------------------------
           INSTALL REDIS VIA ANSIBLE
        --------------------------- */
        stage('Install Redis via Ansible') {
            steps {
                sh '''
                    cd ansible
                    ansible-galaxy install -r requirements.yml
                    ansible-playbook site.yml -i inventory/hosts.ini
                '''
            }
        }

        /* ---------------------------
           REDIS TEST
        --------------------------- */
        stage('Redis Test') {
            steps {
                sh '''
                cd terraform
                MASTER=$(terraform output -raw redis_master_private_ip)
                REPLICA=$(terraform output -raw redis_replica_private_ip)
                BASTION=$(terraform output -raw bastion_public_ip)
                cd ..

                echo "Testing Redis Master:"
                ssh -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -i terraform/redis-demo-key.pem \
                    -J ubuntu@$BASTION ubuntu@$MASTER "redis-cli ping"

                echo "Testing Redis Replica:"
                ssh -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -i terraform/redis-demo-key.pem \
                    -J ubuntu@$BASTION ubuntu@$REPLICA "redis-cli ping"
                '''
            }
        }
    }

    /* ---------------------------
       POST ACTIONS
    --------------------------- */
    post {
        always {
            echo "Pipeline finished."
        }
        failure {
            echo "Pipeline FAILED! Fix errors above."
        }
    }
}
