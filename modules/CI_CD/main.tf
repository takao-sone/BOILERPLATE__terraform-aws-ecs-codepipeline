# CodeCommit ===============================
resource "aws_codecommit_repository" "repo" {
  repository_name = "${var.project_name}-codecommit-repository"
}

# CodeBuild ===============================
resource "aws_codebuild_project" "codebuild" {
  name          = "${var.project_name}-codebuild"
  badge_enabled = true
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    encryption_disabled    = false
    override_artifact_name = false
    type                   = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    git_clone_depth = 1
    insecure_ssl    = false
    location        = aws_codecommit_repository.repo.clone_url_http
    type            = "CODECOMMIT"
  }
}

# CodeDeploy ===============================
resource "aws_codedeploy_app" "app" {
  name             = "${var.project_name}-codedeploy-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "app" {
  deployment_group_name  = "${var.project_name}-codedeploy-deployment-group"
  app_name               = aws_codedeploy_app.app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  tags = {
    Name = "${var.project_name}-cnapp-codedeploy-deployment-group"
  }

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      # action_on_timeout = "CONTINUE_DEPLOYMENT"
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.app_ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          var.alb_http_listener_arn
        ]
      }
      target_group {
        name = var.alb_blue_target_group_name
      }
      target_group {
        name = var.alb_green_target_group_name
      }
      test_traffic_route {
        listener_arns = [
          var.alb_http_test_listener_arn
        ]
      }
    }
  }
}

# CodePipeline ===============================
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact_store.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      configuration = {
        "BranchName"           = "master"
        "OutputArtifactFormat" = "CODE_ZIP"
        "PollForSourceChanges" = "false"
        "RepositoryName"       = aws_codecommit_repository.repo.repository_name
      }
      input_artifacts = []
      name            = "Source"
      namespace       = "SourceVariables"
      output_artifacts = [
        "SourceArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeCommit"
      region    = var.aws_region
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "ProjectName" = aws_codebuild_project.codebuild.name
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name      = "Build"
      namespace = "BuildVariables"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      region    = var.aws_region
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "AppSpecTemplateArtifact"        = "SourceArtifact"
        "ApplicationName"                = aws_codedeploy_app.app.name
        "DeploymentGroupName"            = aws_codedeploy_deployment_group.app.deployment_group_name
        "Image1ArtifactName"             = "BuildArtifact"
        "Image1ContainerName"            = "IMAGE1_NAME"
        "TaskDefinitionTemplateArtifact" = "SourceArtifact"
      }
      input_artifacts = [
        "BuildArtifact",
        "SourceArtifact",
      ]
      name             = "Deploy"
      namespace        = "DeployVariables"
      output_artifacts = []
      owner            = "AWS"
      provider         = "CodeDeployToECS"
      region           = var.aws_region
      run_order        = 1
      version          = "1"
    }
  }
}

# CloudWatch Event ===============================
resource "aws_cloudwatch_event_rule" "codecommit_event" {
  name           = "${var.project_name}-cloudwatch-event-rule"
  description    = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the AWS CodeCommit source repository and branch. Deleting this may prevent changes from being detected in that pipeline. Read more: http://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html"
  event_bus_name = "default"
  is_enabled     = true
  event_pattern = jsonencode(
    {
      detail = {
        event = [
          "referenceCreated",
          "referenceUpdated",
        ]
        referenceName = [
          "master",
        ]
        referenceType = [
          "branch",
        ]
      }
      detail-type = [
        "CodeCommit Repository State Change",
      ]
      resources = [
        aws_codecommit_repository.repo.arn,
      ]
      source = [
        "aws.codecommit",
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "codecommit_event" {
  arn      = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.cloudwatch_event.arn
  rule     = aws_cloudwatch_event_rule.codecommit_event.name
}

# IAM Role ===============================
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"
  path = "/service-role/"
  managed_policy_arns = [
    aws_iam_policy.codebuild.arn,
  ]

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codebuild.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-pipeline-role"
  path = "/service-role/"
  managed_policy_arns = [
    aws_iam_policy.codepipeline.arn,
  ]

  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codepipeline.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "cloudwatch_event" {
  name = "${var.project_name}-cloudwatch-event-role"
  path = "/service-role/"
  managed_policy_arns = [
    aws_iam_policy.cloudwatch_event.arn,
  ]

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "events.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "${var.project_name}-ecs-code-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_role_assume_role_policy_document.json

  tags = {
    Name = "${var.project_name}-ecs-code-deploy-role"
  }
}

# IAM Policy ===============================
resource "aws_iam_policy" "codepipeline" {
  name        = "${var.project_name}-code-pipeline-service-role-policy"
  description = "Policy used in trust relationship with CodePipeline"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "iam:PassRole",
          ]
          Condition = {
            StringEqualsIfExists = {
              "iam:PassedToService" = [
                "cloudformation.amazonaws.com",
                "elasticbeanstalk.amazonaws.com",
                "ec2.amazonaws.com",
                "ecs-tasks.amazonaws.com",
              ]
            }
          }
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "codecommit:CancelUploadArchive",
            "codecommit:GetBranch",
            "codecommit:GetCommit",
            "codecommit:GetRepository",
            "codecommit:GetUploadArchiveStatus",
            "codecommit:UploadArchive",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplication",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "codestar-connections:UseConnection",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "elasticbeanstalk:*",
            "ec2:*",
            "elasticloadbalancing:*",
            "autoscaling:*",
            "cloudwatch:*",
            "s3:*",
            "sns:*",
            "cloudformation:*",
            "rds:*",
            "sqs:*",
            "ecs:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "lambda:InvokeFunction",
            "lambda:ListFunctions",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "opsworks:CreateDeployment",
            "opsworks:DescribeApps",
            "opsworks:DescribeCommands",
            "opsworks:DescribeDeployments",
            "opsworks:DescribeInstances",
            "opsworks:DescribeStacks",
            "opsworks:UpdateApp",
            "opsworks:UpdateStack",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "cloudformation:CreateStack",
            "cloudformation:DeleteStack",
            "cloudformation:DescribeStacks",
            "cloudformation:UpdateStack",
            "cloudformation:CreateChangeSet",
            "cloudformation:DeleteChangeSet",
            "cloudformation:DescribeChangeSet",
            "cloudformation:ExecuteChangeSet",
            "cloudformation:SetStackPolicy",
            "cloudformation:ValidateTemplate",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "codebuild:BatchGetBuildBatches",
            "codebuild:StartBuildBatch",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "devicefarm:ListProjects",
            "devicefarm:ListDevicePools",
            "devicefarm:GetRun",
            "devicefarm:GetUpload",
            "devicefarm:CreateUpload",
            "devicefarm:ScheduleRun",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "servicecatalog:ListProvisioningArtifacts",
            "servicecatalog:CreateProvisioningArtifact",
            "servicecatalog:DescribeProvisioningArtifact",
            "servicecatalog:DeleteProvisioningArtifact",
            "servicecatalog:UpdateProduct",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "cloudformation:ValidateTemplate",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ecr:DescribeImages",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "states:DescribeExecution",
            "states:DescribeStateMachine",
            "states:StartExecution",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "appconfig:StartDeployment",
            "appconfig:StopDeployment",
            "appconfig:GetDeployment",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_policy" "codebuild" {
  name        = "${var.project_name}-code-build-base-policy"
  description = "Policy used in trust relationship with CodeBuild"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:ap-northeast-1:648099517491:log-group:/aws/codebuild/${var.project_name}-codebuild",
            "arn:aws:logs:ap-northeast-1:648099517491:log-group:/aws/codebuild/${var.project_name}-codebuild:*",
          ]
        },
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::${var.project_name}-vvvvv-codepipeline-as",
          ]
        },
        {
          Action = [
            "codecommit:GitPull",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:codecommit:ap-northeast-1:648099517491:${var.project_name}-codecommit-repository",
          ]
        },
        {
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:codebuild:ap-northeast-1:648099517491:report-group/${var.project_name}-codebuild-*",
          ]
        },
        {
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameters",
          ]
          Resource = [
            aws_ssm_parameter.docker_hub_username.arn,
            aws_ssm_parameter.docker_hub_password.arn,
          ]
        }
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_policy" "cloudwatch_event" {
  name        = "${var.project_name}-start-pipeline-execution-policy"
  description = "Allows Amazon CloudWatch Events to automatically start a new execution in the ${var.project_name}-pipeline pipeline when a change occurs"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "codepipeline:StartPipelineExecution",
          ]
          Resource = [
            aws_codepipeline.codepipeline.arn,
          ]
        },
      ]
    }
  )

  tags = {
    Name = "${var.project_name}-start-pipeline-execution-policy"
  }
}

# IAM Policy Document =============================================
data "aws_iam_policy_document" "codedeploy_role_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

# IAM Role Policy Attachment =============================================
resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# S3 ===============================
resource "aws_s3_bucket" "codepipeline_artifact_store" {
  force_destroy = true

  versioning {
    enabled    = false
    mfa_delete = false
  }
}

# SSM Parameter ===============================
resource "aws_ssm_parameter" "docker_hub_username" {
  name  = "${var.project_name}-docker-hub-username"
  type  = "SecureString"
  value = var.docker_hub_username
}

resource "aws_ssm_parameter" "docker_hub_password" {
  name  = "${var.project_name}-docker-hub-password"
  type  = "SecureString"
  value = var.docker_hub_password
}
