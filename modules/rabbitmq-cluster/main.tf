locals {
  admin_port = 15672
  amqp_port  = 5672
}

resource "aws_security_group" "alb" {
  vpc_id = var.vpc_id
  name   = "rabbitmq-alb-sg-${var.environment}"

  ingress {
    from_port   = local.admin_port
    to_port     = local.admin_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.environment }
}

resource "aws_security_group" "nodes" {
  vpc_id = var.vpc_id
  name   = "rabbitmq-nodes-sg-${var.environment}"

  ingress {
    from_port       = local.admin_port
    to_port         = local.admin_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = local.amqp_port
    to_port         = local.amqp_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port = 4369
    to_port   = 4369
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 25672
    to_port   = 25672
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.environment }
}

resource "aws_lb" "main" {
  name               = "rabbitmq-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
  tags = { Environment = var.environment }
}

resource "aws_lb_target_group" "main" {
  name        = "rabbitmq-tg-${var.environment}"
  port        = local.admin_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/api/health"
    port                = local.admin_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = { Environment = var.environment }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = local.admin_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_iam_role" "instance" {
  name = "rabbitmq-ssm-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance.name
}

resource "aws_iam_instance_profile" "instance" {
  name = "rabbitmq-instance-profile-${var.environment}"
  role = aws_iam_role.instance.name
}

resource "aws_launch_template" "rabbitmq" {
  name_prefix   = "rabbitmq-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }
  user_data = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "rabbitmq-node"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "rabbitmq" {
  desired_capacity    = var.node_count
  min_size            = var.node_count
  max_size            = var.node_count
  vpc_zone_identifier = var.private_subnets
  launch_template {
    id      = aws_launch_template.rabbitmq.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.main.arn]
  tag {
    key                 = "Name"
    value               = "rabbitmq-node"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}