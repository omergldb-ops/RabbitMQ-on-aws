variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "node_count" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "rabbitmq-demo"
}