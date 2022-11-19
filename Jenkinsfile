pipeline {
    agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3 -m venv test3
                source test3/bin/activate
                pip install pip --upgrade
                pip install -r requirements.txt
                export FLASK_APP=application
                flask run &
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source test3/bin/activate
                py.test --verbose --junit-xml test-reports/results.xml
                '''
            }
            post{
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
        stage ('Create Image') {
            agent{label 'dockerAgent'}
            steps {
                sh '''#!/bin/bash
                sudo apt update
                sudo apt -y install git
                sleep 3
                git clone https://github.com/herimendoza/kuralabs_deployment_5.git
                sleep 2
                cd kuralabs_deployment_5/
                tar --exclude='./Documentation' --exclude='./Jenkinsfile' --exclude='./READEME.md' --exclude='./intTerraform/' --exclude='./test_app.py' --exclude='./dockerfile' -cvf url_app.tar.gz .
                sudo docker pull python
                sudo docker build -t heripotter/deploy5 .
                sleep 10
                cd ..
                rm -rf kuralabs_deployment_5/

                '''

            }
        }
        stage ('Push to Dockerhub') {
            agent{label 'dockerAgent'}
            steps {
                // create repo beforehand
                // push container to dockerhub (docker push heripotter/<container>)
                // delete local image
                sh '''#!/bin/bash
                sudo docker push heripotter/deploy5:latest
                sudo docker rmi heripotter/deploy5:latest
                '''

            }
        }
        stage ('Deploy to ECS') {
            agent{label 'terraformAgent'}
            steps {
                withCredentials([string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')]) {
                    dir('intTerraform') {
                        sh '''#!/bin/bash
                        terraform init
                        terraform plan -out plan.tfplan -var="aws_access_key=$aws_access_key" -var="aws_secret_key=$aws_secret_key"
                        terraform apply plan.tfplan
                        '''
                    }
                }

            }
        }
        
        stage ('Destroy Infrastructure') {
            agent{label 'terraformAgent'}
            steps {
                withCredentials([string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key')]) {
                    dir('intTerraform') {
                        sh '''#!/bin/bash
                        terraform destroy -auto-approve -var="aws_access_key=$aws_access_key" -var="aws_secret_key=$aws_secret_key"
                        '''
                    }
                }
            }
        }
        
    }
    post{
        always{
            emailext to: "heri.mendoza9@gmail.com",
            subject: "jenkins build:${currentBuild.currentResult}: ${env.JOB_NAME}",
            body: "${currentBuild.currentResult}: Job ${env.JOB_NAME}\nMore Info can be found here: ${env.BUILD_URL}",
            attachLog: true
        }
    }
}
