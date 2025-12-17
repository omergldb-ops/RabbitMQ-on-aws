output "rabbitmq_alb_dns" {
  value = module.rabbitmq_cluster.alb_dns_name
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}