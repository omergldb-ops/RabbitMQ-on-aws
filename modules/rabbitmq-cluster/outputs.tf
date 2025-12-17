data "aws_instances" "rabbitmq" {
  filter {
    name   = "tag:Name"
    values = ["rabbitmq-node"]
  }

  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }

}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "instance_ids" {
  value = data.aws_instances.rabbitmq.ids
}