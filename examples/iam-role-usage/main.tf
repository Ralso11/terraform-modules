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

module "lambda_role" {
  source = "../../iam-role"

  role_name           = "modules-demo-lambda-role"
  assume_role_service = "lambda.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

module "ecs_role" {
  source = "../../iam-role"

  role_name           = "modules-demo-ecs-role"
  assume_role_service = "ecs-tasks.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

output "lambda_role_arn" {
  value = module.lambda_role.role_arn
}

output "ecs_role_arn" {
  value = module.ecs_role.role_arn
}
