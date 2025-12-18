output "rabbitmq_alb_dns" {
  value = module.rabbitmq_cluster.alb_dns_name
}

output "rabbitmq_instance_ids" {
  value = module.rabbitmq_cluster.instance_ids
}