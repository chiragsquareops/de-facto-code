resource "aws_security_group" "laravel-app-alb-sg" {
  name        = "${var.name}-alb-sg"
  depends_on  = [module.alb]
  description = "Allow TLS inbound and outbund traffic"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = [80, 443]
    iterator = port
    content {
      description = "TLS from vpc"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name        = "${var.name}-alb-sg"
    Owner       = var.Owner
    Environment = var.Environment
    Terraform   = var.Terraform
  }
}

module "alb" {
  count              = var.alb_enable ? 1 : 0
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  security_groups    = var.security_groups
  target_groups = [
    {
      name             = "${var.name}-TG"
      backend_protocol = var.backend_protocol
      backend_port     = var.backend_port
      target_type      = var.target_type
      health_check = {
        enabled             = true
        interval            = 6
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
    }
  ]
  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
  tags = {
    name        = "${var.name}-alb-sg"
    Owner       = var.Owner
    Environment = var.Environment
    Terraform   = var.Terraform
  }
}