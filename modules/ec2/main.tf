resource "aws_instance" "webserver" {
  count = var.ec2_config.instance_count

  ami                    = var.ec2_config.ec2_ami
  instance_type          = var.ec2_config.instance_type
  vpc_security_group_ids = [var.security_group_ids[0]]
  subnet_id              = var.pri_subnet[0]
  key_name               = var.ec2_config.key_name
  associate_public_ip_address = false
  user_data_replace_on_change = true
  iam_instance_profile   = aws_iam_instance_profile.ec2_profiles["github-runner"].name

  tags = {
    Name = "${terraform.workspace}-${var.ec2_config.resource_name}-${count.index + 1}"
    RunnerLabel = "${var.ec2_config.labelname}"
    project = "${var.ec2_config.project}"
    environment = "${terraform.workspace}"
  }

  user_data = filebase64("${path.module}/user_data.sh")
}


resource "aws_iam_role" "ec2_roles" {
  for_each = var.ec2_iam_role

  name = each.value.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_custom_policy" {
  for_each = var.ec2_iam_role
  name        = each.value.iam_policy_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = split(",", each.value.ec2_actions),
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "policy_attachment" {
  for_each = var.ec2_iam_role

  name       = "${each.value.iam_role_name}-Attachment"
  roles      = [aws_iam_role.ec2_roles[each.key].name]
  policy_arn = aws_iam_policy.ec2_custom_policy[each.key].arn
}

resource "aws_iam_instance_profile" "ec2_profiles" {
  for_each = var.ec2_iam_role

  name = "${each.value.iam_role_name}-InstanceProfile"
  role = aws_iam_role.ec2_roles[each.key].name
}

