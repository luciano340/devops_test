resource "aws_iam_role" "add_role" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "codebuild.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
}

#Aplicando politica o qual da permissão para registrar logs no CloudWatch
resource "aws_iam_role_policy_attachment" "codebuild-CloudWatchFullAccess" {
  role = aws_iam_role.add_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

#Aplicando politica o qual da permissão para registrar logs no CloudWatch
resource "aws_iam_role_policy_attachment" "codebuild-ecr" {
  role = aws_iam_role.add_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

#Criando codebuild
resource "aws_codebuild_project" "add_codebuild" {
    name = "${var.prefix}-codebuild"
    build_timeout = "120"
    service_role = aws_iam_role.add_role.arn

    #Não é necessário gerar artefato nesse tipo de build
    artifacts {
        type = "NO_ARTIFACTS"
    }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/standard:6.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"
        privileged_mode             =  true
        
        environment_variable {
        name  = "REPO_ECR"
        value = "${var.ecr_url}"
        }
    }

    source {
        type            = "GITHUB"
        location        = "${var.repo_url}"
        git_clone_depth = 1
    }

    tags = {
        Environment = "${var.prefix}-codebuild"
    }
}

#Configura logs para o CloudWatch
resource "aws_cloudwatch_log_group" "log" {
  name = "/aws/Codebuild-terraform/aws_codebuild_project.${var.prefix}-codebuild.id"
  retention_in_days = var.retention_days
}