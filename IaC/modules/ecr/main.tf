#Cria um repositório no ECR
resource "aws_ecr_repository" "add_ecr" {
  name = "ecrninja"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
      name = "${var.prefix}-ecr"
  }
}

#Configurando politica para limpar imagens antigas - 30 dias +

resource "aws_ecr_lifecycle_policy" "add_policy" {
  repository = aws_ecr_repository.add_ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 30 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}