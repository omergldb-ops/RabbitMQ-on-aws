output "asg_name" {
  value = aws_autoscaling_group.rabbitmq_asg.name
}

output "asg_id" {
  value = aws_autoscaling_group.rabbitmq_asg.id
}