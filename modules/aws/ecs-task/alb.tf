
resource "aws_lb" "alb" {
  count              = var.use_load_balancer ? 1 : 0
  name               = "${lower(var.name_prefix)}lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets
  tags               = var.resource_tags
  security_groups    = [aws_security_group.ecs_tasks_sg.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "alb_target_group" {
  count       = var.use_load_balancer ? 1 : 0
  name        = "${var.name_prefix}LB-TargetGroup"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 10
    path                = "/admin/"
    interval            = 30
    matcher             = "200,302"
  }
}

resource "aws_lb_listener" "listener" {
  count             = var.use_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = "8080"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
  }
}
