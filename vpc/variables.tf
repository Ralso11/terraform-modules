variable "project_name" {
  description = "Name used to prefix and tag all resources created by this module"
  type        = string
}

variable "vpc_cidr" {
  description = "IP address range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP address range for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_region" {
  description = "AWS region (used to pick an availability zone)"
  type        = string
}
