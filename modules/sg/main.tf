resource "aws_security_group" "sg" {
  for_each = { for idx, sg in var.security_group : sg.name => sg }

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id[each.value.vpc_name]

  dynamic "ingress" {
    for_each = split(",", each.value.ports)
    content {
      from_port   = tonumber(ingress.value)
      to_port     = tonumber(ingress.value)
      protocol    = "tcp"
      cidr_blocks = split(",", each.value.cidr_blocks)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = each.value.name
    project = var.project
    environment = terraform.workspace
  }
}
