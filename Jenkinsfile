pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
        AWS_REGION = "eu-west-2"
    }

    stages {

        stage('Checkout') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-creds']]) {
                    checkout scm
                    sh 'ls -la'
                }
            }
        }

        stage('Install Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-creds']]) {
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
        }

        stage('Install Ansible') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-creds']]) {
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
        }

        stage('Terraform Init + Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-creds']]) {
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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-creds']]) {
                    dir('ansible') {
                        sh 'ansible-inventory -i inventory.aws_ec2.yml --graph'
                        sh 'ansible-playbook site.yml'
                    }
                }
            }
        }
    }
}
