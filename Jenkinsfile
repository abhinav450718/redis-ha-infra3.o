pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        AWS_REGION = "eu-west-2"
    }

    stages {

        /* ---------------------------
           CHECKOUT CODE
        ---------------------------- */
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:abhinav450718/redis-ha-infra3.o.git',
                        credentialsId: 'github-ssh-key'
                    ]]
                ])
                sh 'ls -la'
            }
        }

        /* ---------------------------
           INSTALL TERRAFORM
        ---------------------------- */
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

        /* ---------------------------
           INSTALL ANSIBLE
        ---------------------------- */
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

        /* ---------------------------
           TERRAFORM INIT & APPLY
        ---------------------------- */
        stage('Terraform Init + Apply') {
            steps {
                withCredentials([aws(
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {

                    dir('terraform') {
                        sh 'terraform init -input=false'
                        sh 'terraform validate'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        /* ---------------------------
           ANSIBLE DEPLOY REDIS CLUSTER
        ---------------------------- */
        stage('Ansible Deploy') {
            steps {
                withCredentials([aws(
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('ansible') {
                        sh 'ansible-inventory -i inventory.aws_ec2.yml --graph'
                        sh 'ansible-playbook site.yml'
                    }
                }
            }
        }

        /* ---------------------------
           SHOW SSH + REDIS DEMO COMMANDS
        ---------------------------- */
        stage('Show SSH Commands & Redis Status') {
            steps {
                script {
                    def bastion = sh(script: "terraform -chdir=terraform output -raw bastion_public_ip", returnStdout: true).trim()
                    def master  = sh(script: "terraform -chdir=terraform output -raw redis_master_private_ip", returnStdout: true).trim()
                    def replica = sh(script: "terraform -chdir=terraform output -raw redis_replica_private_ip", returnStdout: true).trim()

                    echo "==============================="
                    echo "       SSH ACCESS COMMANDS     "
                    echo "==============================="
                    echo "SSH to Bastion:"
                    echo "ssh -i terraform/redis-demo-key.pem ubuntu@${bastion}"
                    echo ""
                    echo "SSH to Redis Master:"
                    echo "ssh -i ~/.ssh/redis-demo-key.pem ubuntu@${master}"
                    echo ""
                    echo "SSH to Redis Replica:"
                    echo "ssh -i ~/.ssh/redis-demo-key.pem ubuntu@${replica}"

                    echo "==============================="
                    echo "       REDIS TEST COMMANDS     "
                    echo "==============================="
                    echo "Check replication (master):"
                    echo "redis-cli info replication"
                    echo ""
                    echo "Check replication (replica):"
                    echo "redis-cli info replication"
                    echo ""
                    echo "Test write on master:"
                    echo "redis-cli set demo 'hello-world'"
                    echo ""
                    echo "Read on replica:"
                    echo "redis-cli get demo"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment Successful!"
        }
        failure {
            echo "❌ Deployment Failed. Check Console Output!"
        }
    }
}
