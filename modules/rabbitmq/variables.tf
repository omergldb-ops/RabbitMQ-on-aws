variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "node_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ami_id" {
  type = string
}