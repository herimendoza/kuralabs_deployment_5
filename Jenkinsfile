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

            }
        }
        stage ('Push to Dockerhub') {
            agent{label 'dockerAgent'}
            steps {

            }
        }
        stage ('Deploy to ECS') {
            agent{label 'terraformAgent'}
            steps {

            }
        }
    }
}
