# Launch Template: Defines the 'blueprint' for each RabbitMQ node
resource "aws_launch_template" "rabbit" {
  name_prefix   = "rabbitmq-node-"
  image_id      = var.ami_id
  instance_type = "t3.medium" # Minimum recommended for clustering

  # Attaches the IAM profile so nodes can 'find' each other in AWS
  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.node_sg_id]

  # Encodes the bootstrap script to install & configure RabbitMQ
  user_data = filebase64("${path.module}/user_data.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "rabbitmq-cluster-node"
      Project = "Task-3"
    }
  }
}

# Auto Scaling Group: Maintains the 3-node cluster requirement
resource "aws_autoscaling_group" "rabbitmq_asg" {
  name                = "rabbitmq-asg"
  desired_capacity    = 3
  max_size            = 3
  min_size            = 3
  vpc_zone_identifier = var.private_subnets # Places nodes in private subnets

  # Connects the instances to the Load Balancer's Target Group
  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.rabbit.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
}