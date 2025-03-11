# modules/vpc/outputs.tf
output "vpc_ids" {
  value = { for k, v in aws_vpc.this : k => v.id }
}

output "public_subnet_ids" {
  value = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  value = { for k, v in aws_subnet.private : k => v.id }
}