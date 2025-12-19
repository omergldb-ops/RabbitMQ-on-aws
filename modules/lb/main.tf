resource "aws_lb" "rabbit_alb" {
  name               = "rabbit-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "rabbit_mgmt" {
  name     = "rabbit-mgmt-tg"
  port     = 15672
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/#/login"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.rabbit_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbit_mgmt.arn
  }
}