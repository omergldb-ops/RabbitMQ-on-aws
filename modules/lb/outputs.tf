output "target_group_arn" {
  value = aws_lb_target_group.rabbit_mgmt.arn
}

output "alb_dns_name" {
  value = aws_lb.rabbit_alb.dns_name
}