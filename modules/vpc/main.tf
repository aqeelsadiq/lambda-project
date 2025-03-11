### modules/vpc/main.tf

resource "aws_vpc" "this" {
  for_each   = var.vpcs
  cidr_block = each.value.cidr
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["vpc"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "public" {
  for_each                = { for subnet in var.pub_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  vpc_id                  = aws_vpc.this[each.value.vpc_name].id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true
  availability_zone       = each.value.availability_zone
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["public_subnet"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "private" {
  for_each          = { for subnet in var.pri_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  vpc_id            = aws_vpc.this[each.value.vpc_name].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["private_subnet"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_internet_gateway" "this" {
  for_each = var.vpcs
  vpc_id   = aws_vpc.this[each.key].id
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["igw"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_eip" "nat" {
  for_each = { for subnet in var.pri_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  domain   = "vpc"
}

resource "aws_nat_gateway" "this" {
  for_each      = { for subnet in var.pri_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  allocation_id = aws_eip.nat[each.key].id
  subnet_id = aws_subnet.public[
    [for pub in var.pub_subnets : "${pub.vpc_name}-${pub.availability_zone}" if pub.vpc_name == each.value.vpc_name][0]
  ].id

  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["nat_gateway"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "public" {
  for_each = var.vpcs
  vpc_id   = aws_vpc.this[each.key].id
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["public_rt"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_route" "public_internet_access" {
  for_each               = var.vpcs
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each       = { for subnet in var.pub_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.value.vpc_name].id
}

resource "aws_route_table" "private" {
  for_each = var.vpcs
  vpc_id   = aws_vpc.this[each.key].id
  tags = {
    Name        = "${terraform.workspace}-${each.value.region}-${var.identifier["private_rt"]}"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_route" "private_nat_gateway" {
  for_each               = { for subnet in var.pri_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  route_table_id         = aws_route_table.private[each.value.vpc_name].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = { for subnet in var.pri_subnets : "${subnet.vpc_name}-${subnet.availability_zone}" => subnet }
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value.vpc_name].id
}
