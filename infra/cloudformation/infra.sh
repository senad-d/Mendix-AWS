#!/bin/bash

###########################################
# This is a script to create CF temp and  #
# prepare CF temp for upload to S3 with   #
# the necessary Parameters                #
###########################################

# Import variables from GitHub Secrets
HZID="$1"
HZN="$2"
CERT="$3"

# Create CloudFormation template for Backend with variables
cat <<EOF >>./infra/cloudformation/infra.yml
---
AWSTemplateFormatVersion : 2010-09-09
Description : project infrastructure

# Set Parameters (values to pass to your template at runtime)
Parameters:
  ProjectName:
    Description: This name will be used for for resource names, keyname and tagging.
    Type: String
    Default: project
  Environment:
    Description: Deployment environment.
    Type: String
    AllowedValues:
      - dev
      - prod
    Default: dev
  VpcCidr:
    Description: What is the CIDR Block of IPv4 IP addresses for VPC?
    Type: String
    Default: 10.1.0.0/16
    AllowedPattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[1-2][0-9]|3[0-2]))?\$"
  PublicSubnetAZaCidr:
    Description: Please enter the IP range (CIDR notation) for the public subnet in the Availability Zone "A"
    Type: String
    AllowedPattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[1-2][0-9]|3[0-2]))?\$"
    Default: 10.1.10.0/24
  PublicSubnetAZbCidr:
    Description: Please enter the IP range (CIDR notation) for the public subnet in the Availability Zone "B"
    Type: String
    AllowedPattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[1-2][0-9]|3[0-2]))?\$"
    Default: 10.1.20.0/24
  PrivateSubnetAZaCidr:
    Description: Please enter the IP range (CIDR notation) for the public subnet in the Availability Zone "A"
    Type: String
    AllowedPattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/([0-9]|[1-2][0-9]|3[0-2]))?\$"
    Default: 10.1.30.0/24
  Certificate:
    Description: What is the Certificate ID?
    Type: String
    Default: $CERT
  HostedZoneId:
    Description: What is the Hosted Zone Id?
    Type: String
    Default: $HZID
  HostedZoneName:
    Description: What is the Hosted Zone Name?
    Type: String
    Default: $HZN

# Metadata (provide additional information about the template)
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - 
        Label:
          default: "VPC for Faregate"
        Parameters:
          - ProjectName
          - Environment
          - VpcCidr
          - PublicSubnetAZaCidr
          - PublicSubnetAZbCidr
          - PrivateSubnetAZaCidr
          - Certificate
          - HostedZoneName
          - HostedZoneId
    
    ParameterLabels:
      ProjectName:
        default: "Project"
      Environment:
        default: "Name"
      VpcCidr:
        default: "VPC CIDR"
      PublicSubnetAZaCidr:
        default: "PublicSubnet A"
      PublicSubnetAZbCidr:
        default: "PublicSubnet B"
      PrivateSubnetAZaCidr:
        default: "PrivateSubnet A"
      Certificate:
        default: "Certificate ID"
      HostedZoneName:
        default: "Hosted Zone Name"
      HostedZoneId:
        default: "Hosted Zone Id"

Resources:
### VPC
  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      InstanceTenancy: default
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.VPC'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

### IGW
  InternetGateway: 
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.IGW'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
    

  VpcInternetGatewayAttachment: 
    Type: AWS::EC2::VPCGatewayAttachment
    Properties: 
      VpcId: !Ref Vpc
      InternetGatewayId: !Ref InternetGateway

### Subnets
  PublicSubnetAZa:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      CidrBlock: !Ref PublicSubnetAZaCidr
      AvailabilityZone: !Select [0, !GetAZs ""]
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.Public.Zone.A'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  PublicSubnetAZb:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      CidrBlock: !Ref PublicSubnetAZbCidr
      AvailabilityZone: !Select [1, !GetAZs ""]
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.Public.Zone.B'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  PrivateSubnetAZa:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      CidrBlock: !Ref PrivateSubnetAZaCidr
      AvailabilityZone: !Select [0, !GetAZs ""]
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.Private.Zone.A'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
      
### RouteTables
  PublicRouteTable: 
    Type: AWS::EC2::RouteTable
    Properties: 
      VpcId: !Ref Vpc
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.Public.RouteTable'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
  
  PrivateRouteTableA: 
    Type: AWS::EC2::RouteTable
    Properties: 
      VpcId: !Ref Vpc
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.Private.RouteTable'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  PublicSubnetAZaRouteTable:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable  
      SubnetId:  !Ref PublicSubnetAZa

  PublicSubnetAZbRouteTable:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable  
      SubnetId:  !Ref PublicSubnetAZb
  
  PrivateSubnetAZaRouteTable: 
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties: 
      RouteTableId: !Ref PrivateRouteTableA
      SubnetId: !Ref PrivateSubnetAZa

  RouteToNAT1: 
   Type: AWS::EC2::Route
   Properties: 
     DestinationCidrBlock: 0.0.0.0/0
     RouteTableId: !Ref PrivateRouteTableA
     NatGatewayId: !Ref NATGatewayA

  RouteToInternetGateway: 
    Type: AWS::EC2::Route
    DependsOn: VpcInternetGatewayAttachment
    Properties: 
      DestinationCidrBlock: 0.0.0.0/0
      RouteTableId: !Ref PublicRouteTable
      GatewayId: !Ref InternetGateway

### NatGateway
  ElasticIP1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.EIP1'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  NATGatewayA:
    Type: AWS::EC2::NatGateway
    DependsOn: VpcInternetGatewayAttachment
    Properties:
      AllocationId: !GetAtt ElasticIP1.AllocationId
      SubnetId: !Ref PublicSubnetAZa
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.NAT1'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

### Load Balancer
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub '\${ProjectName}-\${Environment}-\${AWS::Region}-ALB'
      Scheme: internet-facing
      IpAddressType: 'ipv4'
      Type: application
      SecurityGroups: 
        - !GetAtt ALBSecurityGroup.GroupId
      Subnets:
      - !Ref PublicSubnetAZa
      - !Ref PublicSubnetAZb
      Tags:
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      HealthCheckIntervalSeconds: 60
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 5
      TargetType: ip
      Matcher:
        HttpCode: 200-499
      Name: !Sub '\${Environment}-\${ProjectName}-TG'
      Port: 8080
      Protocol: HTTP
      UnhealthyThresholdCount: 3
      VpcId: !Ref Vpc

  HTTPSListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      Certificates:
      - CertificateArn: !Ref Certificate
      DefaultActions:
      - TargetGroupArn: !Ref TargetGroup
        Type: forward
      LoadBalancerArn: !Ref ALB
      Port: 443
      Protocol: 'HTTPS'
      SslPolicy: 'ELBSecurityPolicy-2016-08'

  HTTPListener:
    Type: 'AWS::ElasticLoadBalancingV2::Listener'
    Properties:
      DefaultActions:
      - Type: redirect
        RedirectConfig:
          Port: '443'
          Protocol: HTTPS
          StatusCode: HTTP_301
      LoadBalancerArn: !Ref ALB
      Port: 80
      Protocol: HTTP

### DNS
  DnsRecords:
    Type: AWS::Route53::RecordSetGroup
    DependsOn: ALB
    Properties:
      HostedZoneId: !Ref HostedZoneId
      Comment: Zone apex alias targeted to ELB LoadBalancer.
      RecordSets:
      - Name: !Sub feedback.\${HostedZoneName}
        Type: A
        AliasTarget:
          HostedZoneId: !GetAtt 'ALB.CanonicalHostedZoneID'
          DNSName: !GetAtt 'ALB.DNSName'
    
### ECS Cluster
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '\${ProjectName}-\${Environment}-ECS-cluster'
      ServiceConnectDefaults: 
        Namespace: !Sub '\${ProjectName}-\${Environment}-ECS-App'
      Tags:
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

### EFS
  EFSMountTargetDB:
    Type: AWS::EFS::MountTarget
    Properties:
      FileSystemId: !ImportValue project-AppSystemFiles
      SubnetId: !Ref PrivateSubnetAZa
      SecurityGroups: [!Ref EFSTargetSecurityGroup]

### SecurityGroups
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !Ref Vpc
      GroupDescription: !Sub '\${ProjectName} \${Environment} ALB Security Group'
      SecurityGroupIngress:
      - CidrIp: '0.0.0.0/0'
        FromPort: 443
        ToPort: 443
        IpProtocol: 'tcp'
      - CidrIp: '0.0.0.0/0'
        FromPort: 80
        ToPort: 80
        IpProtocol: 'tcp'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.ALB.SG'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  AppSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    DependsOn: ALBSecurityGroup
    Properties:
      VpcId: !Ref Vpc
      GroupDescription: Access to the Fargate service and the tasks/containers that run on them
      SecurityGroupIngress:
      - CidrIp: !Ref VpcCidr
        FromPort: 5432
        ToPort: 5432
        IpProtocol: 'tcp'
      - SourceSecurityGroupId: !Ref ALBSecurityGroup
        FromPort: 8080
        ToPort: 8080
        IpProtocol: 'tcp'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.AppFargate.SG'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  EFSTargetSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: EFS Mount Access
      VpcId: !Ref Vpc
      SecurityGroupIngress:
      - CidrIp: !Ref VpcCidr
        IpProtocol: '-1'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.EFS.SG'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
  
  DBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    DependsOn: EFSTargetSecurityGroup
    Properties:
      VpcId: !Ref Vpc
      GroupDescription: Access to the Fargate service
      SecurityGroupIngress:
      - CidrIp: !Ref VpcCidr
        FromPort: 5432
        ToPort: 5432
        IpProtocol: 'tcp'
      - SourceSecurityGroupId: !Ref EFSTargetSecurityGroup
        IpProtocol: '-1'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.DBFargate.SG'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
      
### Roles
  EcsTaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
        - Effect: Allow
          Principal:
            Service: [ecs-tasks.amazonaws.com]
          Action: ['sts:AssumeRole']
      Path: /
      Policies:
        - PolicyName: !Sub '\${ProjectName}.\${Environment}.EcsTaskExecutionRolePolicy'
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
            - Effect: Allow
              Action:
                - 'ecr:GetAuthorizationToken'
                - 'ecr:BatchCheckLayerAvailability'
                - 'ecr:GetDownloadUrlForLayer'
                - 'ecr:BatchGetImage'
                - 'logs:CreateLogStream'
                - 'logs:PutLogEvents'
                - 'logs:CreateLogGroup'
                - 'elasticfilesystem:ClientWrite'
                - 'elasticfilesystem:ClientMount'
              Resource: '*'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.EcsTaskExecutionRole'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}
  
  EcsTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
        - Effect: Allow
          Principal:
            Service: [ecs-tasks.amazonaws.com]
          Action: ['sts:AssumeRole']
      Path: /
      Policies:              
        - PolicyName: !Sub '\${ProjectName}.\${Environment}.SESPolicy'
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
            - Effect: Allow
              Action:
              - ses:*
              Resource: '*'
        - PolicyName: !Sub '\${ProjectName}.\${Environment}.SSOPolicy'
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
            - Effect: Allow
              Action:
              - 'iam:ListPolicies'
              - 'ds:DescribeTrusts'
              - 'ds:UnauthorizeApplication'
              - 'ds:DescribeDirectories'
              - 'ds:AuthorizeApplication'
              - 'organizations:EnableAWSServiceAccess'
              - 'organizations:ListRoots'
              - 'organizations:ListAccounts'
              - 'organizations:ListOrganizationalUnitsForParent'
              - 'organizations:ListAccountsForParent'
              - 'organizations:DescribeOrganization'
              - 'organizations:ListChildren'
              - 'organizations:DescribeAccount'
              - 'organizations:ListParents'
              - 'organizations:ListDelegatedAdministrators'
              - 'sso:*'
              - 'sso-directory:*'
              - 'identitystore:*'
              - 'identitystore-auth:*'
              - 'ds:CreateAlias'
              - 'access-analyzer:ValidatePolicy'
              Resource: '*'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.EcsAppTaskRole'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

  EcsDBTaskRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
        - Effect: Allow
          Principal:
            Service: [ecs-tasks.amazonaws.com]
          Action: ['sts:AssumeRole']
      Path: /
      Policies:              
        - PolicyName: !Sub '\${ProjectName}.\${Environment}.EFSDBPolicy'
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
            - Effect: Allow
              Action:
              - 'elasticfilesystem:ClientMount'
              - 'elasticfilesystem:ClientWrite'
              Resource: '*'
      Tags:
      - {Key: Name, Value: !Sub '\${ProjectName}.\${Environment}.EcsDBTaskRole'}
      - {Key: Project, Value: !Ref ProjectName}
      - {Key: Environment, Value: !Ref Environment}

### Parameters
  ALBSGParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.ALB.SG.\${ProjectName}'
      Type: String
      Value: !Ref ALBSecurityGroup
      Description: SSM Parameter for security group

  AppSGParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.AppSG.\${ProjectName}'
      Type: String
      Value: !Ref AppSecurityGroup
      Description: SSM Parameter for App security group

  DBSGParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.SG.\${ProjectName}.Postgres'
      Type: String
      Value: !Ref DBSecurityGroup
      Description: SSM Parameter for Postgres security group

  PublicSubnetAParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.PublicSubnetA.\${ProjectName}'
      Type: String
      Value: !Ref PublicSubnetAZa
      Description: SSM Parameter for subnet

  PublicSubnetBParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.PublicSubnetB.\${ProjectName}'
      Type: String
      Value: !Ref PublicSubnetAZb
      Description: SSM Parameter for subnet

  PrivateSubnetParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.PrivateSubnet.\${ProjectName}'
      Type: String
      Value: !Ref PrivateSubnetAZa
      Description: SSM Parameter for subnet

  EFSMountTargetDBParameterDB:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.EFSMountTargetDB.\${ProjectName}'
      Type: String
      Value: !Ref EFSMountTargetDB
      Description: SSM Parameter for EFSMountPrivateTarget

  ECSClusterParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.ECSCluster.\${ProjectName}'
      Type: String
      Value: !Ref ECSCluster
      Description: SSM Parameter for ECSCluster

  EcsTaskExecutionRoleParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.EcsTaskExecutionRole.\${ProjectName}'
      Type: String
      Value: !GetAtt EcsTaskExecutionRole.Arn
      Description: SSM Parameter for EcsTaskExecutionRole
  
  EcsTaskRoleParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.EcsTaskRole.\${ProjectName}'
      Type: String
      Value: !GetAtt EcsTaskRole.Arn
      Description: SSM Parameter for EcsTaskRoleParameter

  EcsDBTaskRoleParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub '\${Environment}.EcsDBTaskRole.\${ProjectName}'
      Type: String
      Value: !GetAtt EcsDBTaskRole.Arn
      Description: SSM Parameter for EcsDBTaskRoleParameter

### Outputs
Outputs:
  Vpc:
    Description: Vpc for the Mendix App
    Value: !Ref Vpc
    Export:
      Name: project-AppVpc
  ECSCluster:
    Description: ECSCluster 
    Value: !Ref ECSCluster
    Export:
      Name: project-AppECSCluster
  PublicSubnetAZa:
    Description: ECSCluster 
    Value: !Ref PublicSubnetAZa
    Export:
      Name: project-AppPublicSubnetAZa
  EFSMountPrivateTargetDB:
    Description: EFS DB
    Value: !Ref EFSMountTargetDB
    Export:
      Name: project-EFSMountTargetDB
EOF
