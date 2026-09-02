terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source = "../../vpc"

  project_name       = "modules-demo"
  aws_region         = "eu-central-1"
  vpc_cidr           = "10.5.0.0/16"
  public_subnet_cidr = "10.5.1.0/24"
}

output "demo_vpc_id" {
  value = module.vpc.vpc_id
}

output "demo_public_subnet_id" {
  value = module.vpc.public_subnet_id
}
