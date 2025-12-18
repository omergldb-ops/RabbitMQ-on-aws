output "rabbitmq_management_url" {
  description = "URL for the RabbitMQ Management Console"
  value       = "http://${module.lb.alb_dns_name}"
}