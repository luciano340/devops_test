#Definindo versões para a execução do terraform
terraform {
    required_version = ">=1.2.9"
    required_providers {
      aws = ">=4.30.0"
      local = ">=2.2.3"
    }
    #Importante para retirar o tfstate da máquina local.
    backend "s3" {
      bucket = "ninjabucketluromao"
      key    = "terraform.tfstate"
      region = "us-east-1"
    }
}

#Definindo região
provider "aws" {
  region = "us-east-1"
}

#Chamando o módulo "próprio" para a criação da rede/VPS
module "new-vpc" {
  source = "./modules/vpc"
  prefix = var.prefix
  vpc_cidr_block = var.vpc_cidr_block
  desired_subnets = var.desired_subnets
}

module "eks" {
    source = "./modules/eks"
    prefix = var.prefix
    vpc_id = module.new-vpc.vpc_id
    cluster_name = var.cluster_name
    retention_days = var.retention_days
    subnet_ids = module.new-vpc.subnet_ids
    desired_size = var.desired_size
    desired_cluster = var.desired_cluster
    max_size = var.max_size
    min_size = var.min_size
    instance_types = var.instance_types
}

module "ecr" {
  source = "./modules/ecr"
  prefix = var.prefix
}

module "codebuild" {
  source = "./modules/codebuild"
  prefix = var.prefix
  policy_arn = module.eks.role_arn
  retention_days = var.retention_days
  ecr_url = module.ecr.ecr_url
}