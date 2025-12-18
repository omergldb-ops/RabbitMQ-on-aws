output "node_sg_id"            { value = aws_security_group.rabbitmq_nodes.id }
output "alb_sg_id"             { value = aws_security_group.alb_sg.id }
output "instance_profile_name" { value = aws_iam_instance_profile.rabbit_profile.name }