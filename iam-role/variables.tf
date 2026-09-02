variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "assume_role_service" {
  description = "The AWS service principal allowed to assume this role (e.g. lambda.amazonaws.com, ecs-tasks.amazonaws.com)"
  type        = string
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to this role"
  type        = list(string)
  default     = []
}
