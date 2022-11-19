# **Deployment 5**

##### **Author: Heriberto Mendoza**

##### **Date: 18 November 2022**

---

### **Objective:**

The goal of this deployment is to continue gaining familiarity with the CI/CD pipeline, Terraform and Docker. A simple web application will be containerized and deployed across an AWS VPC created with Terraform using Jenkins, Docker and AWS Elastic Container Service.

---

#### ***1. Setting up the Managing Environment***

The managing environment consisted of one Jenkins manager and two Jenkins agents, one with Docker and the other with Terraform. The configuring of each EC2 is described below.

#### 1a. Jenkins Manager:

An EC2 Linux server instance was spun up in the default VPC with default-jre and Jenkins (designated the Jenkins manager). The security group for this instance opened up ports 22, 80 and 8080 for ingress traffic. Python3-venv and python3-pip packages were also installed to ensure that the server could build the application later in the pipeline. After the EC2s were set up with their respective programs (see below), they were connected to the Jenkins manager as Agents. This was done through the Jenkins GUI accessed through <instance ip>:8080. The two instances were added as nodes by uploading their public IPs. Since the manager would be accessing the agents through SSH, the SSH key that the instances were configured to use (during setup) was also uploaded. In addition to the AWS SSH key, an AWS user key pair was added (access key and secret key) to Jenkins. This key pair belonged to a user that was granted enough access in IAM to allow Terraform to create the infrastruction later on. Other credentials that were needed include a GitHub access token to allow Jenkins to pull the latest version of the code at various instances in the pipeline and a Gmail access token to give Jenkins the ability to send an email notification with a build log at the end.

#### 1b. Jenkins Docker Agent:

Since Docker and Terraform were both going to be used in the pipeline, it was decided to use two separate agent instances (one for each) in the hope of preventing a crash during a build due to lack of resources. A second EC2 instance was spun up, also in the default VPC. The default-jre package was installed to ensure that Jenkins could run on it as an agent. To install Docker, instructions from the Docker official documentation were used: https://docs.docker.com/engine/install/ubuntu/ . Once docker was installed, the command `$sudo docker login` was ran in order to provide login credentials from docker hub. This would allow docker to push images to docker hub automatically later on.

#### 1c. Jenkins Terraform Agent:

A third EC2 instance was spun up in the default VPC. In this case, default-jre and Terraform were installed in order to allow this agent to launch the deployment infrastructure using Terraform. Commands were taken directly from the Terraform documentaiton: https://www.terraform.io/downloads .


#### ***2. The Jenkinsfile***

Before any work was done, the repository with the source code and other necessary files was forked and then cloned to a local machine. Git was used for version control.

The Jenkinsfile for this pipeline consisted of 6 stages in total. They are described below.

#### 2a. The 'Build' Stage:

```console
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
```

The agent label 'Any' means that this stage is carried out in the Jenkins Manager EC2. A virtual environment is created, activated, and pip (python package manager) installs the required dependencies necessary for the application to run. Finally, the application is run in the background.

#### 2b. The 'Test' Stage:

```console
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
```

The agent label 'Any' means that this stage is also carried out in the Jenkins Manager EC2. The virtual environment is activated again and py.test runs any code that begins with 'test'. In this case, an instance of the application is run and the test tries to access the root page. The response code is checked to verify if it is a successful (200) response. Junit subsequently creates an xml report of the test result and saves it in the workspace directory of the Jenkins server.

#### 2c. The 'Create Image' Stage:

```console
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
```

The agent label 'dockerAgent' specifies that this stage is to take place in the EC2 running Docker. In the agent, the repositories are updated and git is installed. The repository containing the source code cloned to the server. Next, a tar ball of the source code is created, excluding all unnecessary files. Once the compressed archive is created, a base python image is pulled from dockerhub. This image is modified using `$docker build` and the dockerfile in the repository:

```console
FROM python:latest

RUN apt update

WORKDIR /app

ADD ./url_app.tar.gz .

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

EXPOSE 5000

ENTRYPOINT FLASK_APP=application flask run --host=0.0.0.0
```

In the base python image, the repositories are updated and a new directory is created. ADD adds the compressed source code to the image and unzips it. pip is used to install the necessary dependencies. EXPOSE ensures that the image port opeend is 5000 (flask default port) and ENTRYPOINT ensures that whenever a container using this image is run, flask is automatically run.

Finally, for cleanup purposes, the cloned directory is deleted.

#### 2d. The 'Push to Dockerhub' stage:

```console
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
```

The agent label 'dockerAgent' ensures that this stage of the pipeline also takes place in the Docker agent EC2. A short script is ran to push the container to a repository in dockerhub and delete the local image (to ensure that if the pipeline deployed again, the correct image is pushed). This stage is possible because (as mentioned before), the command `$docker login` was used to input credentials during the set up phase.

#### 2e. The 'Deploy to ECS' stage:

```console
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
```

The agent label 'terraformAgent' specifies that this stage is to take place in the Terraform EC2. The credentials that were supplied in the Jenkins GUI are passed as variables into Terraform (giving Terraform access to AWS) to create, plan and apply the infrastructure. The infrastructure will be discussed later in the documentation.

#### 2f. The 'Destroy Infrastructure' stage:

```console
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
```

The agent label 'terraformAgent' specifies that this stage is to take place in the Terraform EC2. Using the same AWS credentials, the infrastructure is destroyed with `$terraform destroy`. This block of code was commented out as needed.

#### 2g. The 'Post' stage:

```console
post{
    always{
        emailext to: "heri.mendoza9@gmail.com",
        subject: "jenkins build:${currentBuild.currentResult}: ${env.JOB_NAME}",
        body: "${currentBuild.currentResult}: Job ${env.JOB_NAME}\nMore Info can be found here: ${env.BUILD_URL}",
        attachLog: true
    }
}
```

The 'Post' stage at the end simply send an email notification using the credentials provided, with he build log attached.

#### ***3. The Terraform Infrastructure***

The deployment infrastructure was created using the Terraform files in the repository. Below is a diagram of the entire infrastructure. Some notable points:

1. A VPC was created with two public subnets, two private subnets, corresponding route tables, a NAT gateway an internet gateway, and two securtiy groups (one that opens port 80 and another that opens port 5000). The pairs of private and public subnets were specified to be in different availability zones.

2. An application load balancer was created in three parts: an ALB, a listening group, and a target group. The ALB was internet-facing, attached to the two public subnets. The HTTP security group was also attached with it, allowing for HTTP traffic (port 80). The listenting group associated with the ALB listens on port 80 and forwards requests to the target group. The target group has port 5000 open (Flask default port).

3. A task definiton resource was created. This specified the image to be pulled from dockerhub (the one that was created in the pipeline), the container port (5000), resulting in a container. The container was deployed in ECS in a Fargate type setup (no EC2s, just containers). The ECS resource in Terraform specified the subnets that the container would be deployed to (private subnets), the port that would be opened (5000) and the load balancer that would direct traffic to the cluster. In summary, the ALB would direct traffic to the ECS cluser that would host Fargate containers of the application in the private subnets.

#### ***4. Issues***

One issue that was observed during testing of the individual stages was the need for docker credentials in order to push to a docker repository. My solution was to SSH into the agent and manually enter the credentials. An alternative and more elegant solution would have been to use the docker plugin in Jenkins and add the credentials in the Jenkins GUI.

Another issue that kept popping up is that every now and then, the URL for the application load balancer would return a 503 Error, even though the deployment and infrastructure was supposed to be up. A couple of refreshes later and the applicatin would be back. It was unclear why this happened.


#### ***5. Improvements***

1. In the interest of readability the script to generate the containerized app could have been written in another file and then called in the jenkinsfile.

2. In the default configurations, two agents were used in addition to the manager. Instead of two agents running Docker and Terraform, one more powerful instance could be used to run both Docker and Terraform.

3. To mimic the resiliency and redundancy in the deployment infrastructure, two EC2s (with a greater amount of resources) could be placed in separate subnets in different availability zones, both running Docker and Terraform. This way, if one agent goes down, all the stages can still occur in the pipeline.