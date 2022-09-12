terraform {
    required_version = ">=1.2.9"
    required_providers {
      aws = ">=4.30.0"
      local = ">=2.2.3"
    }
}

#Criando bucket
resource "aws_s3_bucket" "add_bucket" {
  bucket = "${var.bucket_name}"

  tags = {
      Name = "${var.prefix}-s3"
  }
}

#Habilitando versionamento
resource "aws_s3_bucket_versioning" "add_version" {
  bucket = aws_s3_bucket.add_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Deixando o bucket privado.
resource "aws_s3_bucket_acl" "acl_bucket" {
  bucket = aws_s3_bucket.add_bucket.id
  acl    = "private"
}

#Configurando logs
resource "aws_s3_bucket_logging" "add_log" {
  bucket = aws_s3_bucket.add_bucket.id

  target_bucket = aws_s3_bucket.add_bucket.id
  target_prefix = "logs/"
}