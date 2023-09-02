#!/bin/bash

ENV="$1"
AZ="$2"
LOGS="$(aws ssm get-parameter --name "$ENV.LogGroup.project" --query "Parameter.Value" --output text)"
EFS="$(aws ssm get-parameter --name "$ENV.AppSystemFiles.project" --query "Parameter.Value" --output text)"
TASKROLE="$(aws ssm get-parameter --name "$ENV.EcsDBTaskRole.project" --query "Parameter.Value" --output text)"
TASKEXROLE="$(aws ssm get-parameter --name "$ENV.EcsTaskExecutionRole.project" --query "Parameter.Value" --output text)"

# Create new task definition
cat <<EOF >>./infra/ecs/db-task.json
{
  "containerDefinitions": [
    {
      "name": "postgres",
      "image": "postgres:15-alpine",
      "essential": true,
      "memory": 2048,
      "environment": [
        {
          "name": "POSTGRES_USER",
          "value": "mendix"
        },
        {
          "name": "POSTGRES_PASSWORD",
          "value": "mendix"
        },
        {
          "name": "PGDATA",
          "value": "/var/lib/postgresql/data/wsm"
        }
      ],
      "mountPoints": [
        {
            "sourceVolume": "efs-db",
            "containerPath": "/var/lib/postgresql/data"
        }
      ],
      "portMappings": [
        {
          "containerPort": 5432,
          "hostPort": 5432,
          "protocol": "tcp"
        }
      ],
      "healthCheck": {
        "command": ["CMD", "pg_isready", "-U", "mendix"],
        "interval": 5,
        "timeout": 2,
        "startPeriod": 10,
        "retries": 10
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
  "volumes": [
      {
          "name": "efs-db",
          "efsVolumeConfiguration": {
            "fileSystemId": "$EFS"
          }
      }
  ],
  "family": "project-DB-TaskDefinition",
  "cpu": "1024",
  "memory": "2048",
  "networkMode": "awsvpc",
  "taskRoleArn": "$TASKROLE",
  "executionRoleArn": "$TASKEXROLE",
  "runtimePlatform": {
    "operatingSystemFamily": "LINUX"
  },
  "requiresCompatibilities": ["FARGATE"]
}
EOF
