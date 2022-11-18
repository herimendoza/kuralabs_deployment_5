# **Deployment 5**

##### **Author: Heriberto Mendoza**

##### **Date: 18 November 2022**

---

### **Objective:**

The goal of this deployment is to continue gaining familiarity with the CI/CD pipeline, Terraform and Docker. A simple web application will be deployed across an AWS VPC created with Terraform using Jenkins and AWS Elastic Container Service.

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

