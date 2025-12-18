variable "aws_region" {
  type        = string
  description = "AWS region (must match default VPC region)"
  default     = "us-east-1"
}

variable "rabbitmq_node_count" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_id" {
  type        = string
  description = "SSM-enabled AMI"
  default     = "ami-068c0051b15cdb816"
}

variable "environment" {
  type    = string
  default = "rabbitmq-demo"
}

variable "perform_instance_refresh" {
  description = "When true, trigger an immediate instance refresh after apply. Requires AWS CLI on the machine running Terraform."
  type        = bool
  default     = false
}