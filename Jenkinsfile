pipeline {
    agent any
    stages {
        stage ('Buiild') {
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
        stage ('Create Container') {
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
                docker pull python
                docker build -t heripotter/deploy5 .

                '''

            }
        }
        stage ('Push to Dockerhub') {
            agent{label 'dockerAgent'}
            steps {
                // create repo beforehand
                // push container to dockerhub (docker push heripotter/<container>)
                sh '''#!/bin/bash
                docker push heripotter/deploy5
                '''

            }
        }
        stage ('Deploy to ECS') {
            agent{label 'terraformAgent'}
            steps {
                // do i need terraform init plan apply? maybe 3 steps?

            }
        }
        stage ('Destroy Infrastructure') {
            agent{label 'terraformAgent'}
            steps {
                // terraform destroy

            }
        }
        stage ('Clean Up') {
            agent{label 'dockerAgent'}
            steps {
                // docker - remove images -- containers are destroyed with ecs
                // cannot create images and conainers with same name?

            }

        }
    }
}
