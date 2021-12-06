# BOILERPLATE for AWS Basic ECS with Terraform

## SETUP

git-secrets
```shell
cd /path/to/my/repo
git secrets --install
git secrets --register-aws
```

Terraform
```shell
touch terraform.tfvars
terraform init
terraform get
terraform plan
terraform apply
```

## Main Resources
### Networking
1. VPC
2. Internet Gateway
3. 4 VPC endpoints  
   (ecr_api, ecr_dkr, s3, ecs_awslogs)
4. 4 Subnets  
   (public, private_container, private_db, private_endpoint)
5. 2 Route Tables (1ついらないかも)  
   (for public subnets, for private containers????)
6. Security Group
   (for vpc_endpoints)

### ALB
1. ALB
2. 2 ALB Listeners
   (real & test)
3. 2 ALB Target Groups
   (Blue & Green)
4. Security Group for ALB

### ECS
1. ECR
2. Cluster
3. Service
4. Service Discovery (Cloud Map)
5. Task Definition
6. Auto Scaling Setting
7. Security Group for container
8. Cloud Watch Log Group
9. IAM Role for task_execution & task
10. 2 IAM Assume Role Policies

### Deploy
1. CodeCommit
