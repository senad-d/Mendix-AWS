![Mendix_on_AWS](https://github.com/senad-d/Mendix-AWS/assets/112484166/c0763430-d49e-4ea1-9e54-6cb0a2a5b86c)

AWS CloudFormation template with GitHub Actions for running the Mendix app
![Mendix_app](https://github.com/senad-d/Mendix-AWS/assets/112484166/8cf58a0a-eabb-4df4-80cc-00fa1aea1a55)

### Quick guide
Create AWS Static resources from the CloudFormation template so that we can create GitHub Action that creates a new CloudFormation template for the AWS Infrastructure template, and then upload it to a private S3 bucket for later use in GitHub Action for creating infrastructure resources.
1. Create a GitHub repository and push all the necessary files for the project.
2. Create Static resources from the CloudFormation template.
3. Run the Action for Building the Docker image and the Action for creating and copying CloudFormation templates to the S3 bucket.
4. Actions for Starting and Ending the entire environment are configured to run automatically at a specific time.
	1. Create Infrastructure for the environment with the CloudFormation template
	2. Create ECS Service for Postgres container using EFS for persistent storage.
	3. Create ECS Service for Mendix container in two AZ-s with LoadBalancer and Route53.
	4. Stop all ECS Services.
	5. Delete Infrastructure
5. Action for Updating the Mendix application is ruined every time the .mpr (Mendix) file is pushed.
---


For the CD/CI pipeline, the next workflows will be used:
- Create and Copy CF temp to S3
	- Use bash script to create a CloudFormation template for the Infrastructure
	- Copy infrastructure templates
- Build and Push Mendix Image
	- Build a docker image
	- Tag docker image
	- Push the docker image to a repository
- Projects/WorkSpaceManager/Git/Create AWS Infrastructure
	- Create Mendix application stack
- Projects/WorkSpaceManager/Git/Build and Deploy Postgres DB
	- Create DataBase Task Definition
	- Register DataBase Task Definition
	- Create a Private Database Fagate Service
- Build and Deploy the Mendix App
	- Create App Task Definition
	- Register App Task Definition
	- Create a two Public Mendix Fargate Service
- Stop Fargate Services
	- Stop Mendix Application Services
- Delete AWS Infrastructure
	- Delete the Mendix application stack
- Update and Push the new image
	- Build a docker image
	- Tag docker image
	- Push the docker image to a repository
	- Update the ECS cluster with a new image

![Mendix_actions](https://github.com/senad-d/Mendix-AWS/assets/112484166/317ef190-a576-4b3c-b1d2-db1c453baf6f)


We will use the CloudFormation templates for AWS to provision resources and Task Definitions for ECS Services.
- AWS static Infrastructure
	- S3 - CloudFormation templates
	- ECR - Mendix Docker image
	- EFS - database persistent files
	- LogGroup - ECS logs
- AWS Application Infrastructure
	- VPC
	- IGW
	- Subnets
	- RouteTables
	- NatGateway
	- Load Balancer
	- Route53
	- ECS Cluster
	- EFS MountTarget
	- Security Groups
	- Roles
	- Parameters
	- Outputs
- Create ECS Task Definition for DB
	- Pull the AWS parameters and place them in the variables
	- Create a YAML file for Task Definition
- Create ECS Task Definition for Mendix
	- Pull the AWS parameters and place them in the variables
	- Create a YAML file for Task Definition


For building a Docker image the  Mendix Buildpack for Docke is used
- Docker Mendix Buildpack
	- Create a Docker image from the Mendix application
