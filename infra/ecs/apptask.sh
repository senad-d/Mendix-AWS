#!/bin/bash

ADMIN="$1"
ENV="$2"
AZ="$3"
ID="$(aws sts get-caller-identity --query "Account" --output text)"
LOGS="$(aws ssm get-parameter --name "$ENV.LogGroup.project" --query "Parameter.Value" --output text)"
TASKEXROLE="$(aws ssm get-parameter --name "$ENV.EcsTaskExecutionRole.project" --query "Parameter.Value" --output text)"
TASKROLE="$(aws ssm get-parameter --name "$ENV.EcsTaskRole.project" --query "Parameter.Value" --output text)"
ECR="$(aws ssm get-parameter --name "$ENV.ECRepo.project" --query "Parameter.Value" --output text)"
ECS="$(aws ssm get-parameter --name "$ENV.ECSCluster.project" --query "Parameter.Value" --output text)"
TASK=$(aws ecs list-tasks --cluster "$ECS" --desired-status RUNNING --query 'taskArns[0]' --output text | awk '{print substr($0,length-31)}')
IP=$(aws ecs describe-tasks --cluster "$ECS" --tasks "$TASK" --query 'tasks[].containers[].networkInterfaces[].privateIpv4Address' --output text)

# Create new Database private IP parameter
aws ssm put-parameter --name "$ENV.Postgresql.IP.project" --type "String" --value "$IP" --overwrite

# Create new task definition
cat <<EOF >>./infra/ecs/mendix-task.json
{
  "containerDefinitions": [
    {
      "name": "project",
      "image": "$ID.dkr.ecr.$AZ.amazonaws.com/$ECR:latest",
      "memory": 2048,
      "essential": true,
      "environment": [
        {
          "name": "ADMIN_PASSWORD",
          "value": "$ADMIN"
        },
        {
          "name": "DATABASE_ENDPOINT",
          "value": "postgres://mendix:mendix@$IP:5432/mendix"
        },
        {
          "name": "DEBUGGER_PASSWORD",
          "value": "$ADMIN"
        },
        {
          "name": "BUILDPACK_XTRACE",
          "value": "true"
        }
      ],
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "healthCheck": {
        "command": ["CMD", "echo", "WORKING"],
        "interval": 5,
        "timeout": 3,
        "startPeriod": 10,
        "retries": 3
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "$LOGS",
          "awslogs-region": "$AZ",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "family": "project-TaskDefinition",
  "cpu": "1024",
  "memory": "2048",
  "networkMode": "awsvpc",
  "executionRoleArn": "$TASKEXROLE",
  "taskRoleArn": "$TASKROLE",
  "runtimePlatform": {
    "operatingSystemFamily": "LINUX"
  },
  "requiresCompatibilities": ["FARGATE"]
}
EOF
