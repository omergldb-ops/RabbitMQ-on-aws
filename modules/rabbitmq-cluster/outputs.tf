output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "instance_ids" {
  value = aws_autoscaling_group.rabbitmq.id
}