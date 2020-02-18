resource "aws_vpc" "fk" {
  cidr_block           = local.network.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
	Name = local.env
  }
}

resource "aws_internet_gateway" "fk" {
  vpc_id = aws_vpc.fk.id

  tags = {
	Name = local.env
  }
}

resource "aws_subnet" "public" {
  for_each                = local.network.azs
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = each.value.public
  availability_zone       = each.key
  tags = {
	Name = "${local.env} public ${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each                = local.network.azs
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = each.value.private
  availability_zone       = each.key
  tags = {
	Name = "${local.env} public ${each.key}"
  }
}

resource "aws_route" "public_access" {
  route_table_id         = aws_vpc.fk.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fk.id
}

resource "aws_eip" "gw-a" {
}

resource "aws_nat_gateway" "fk-gw-a" {
  allocation_id = aws_eip.gw-a.id
  subnet_id     = aws_subnet.public["us-east-1a"].id
  depends_on    = [ aws_internet_gateway.fk ]

  tags = {
	Name = "${local.env} gateway"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = aws_vpc.fk.id

  route {
    cidr_block = "172.31.0.0/16"
	vpc_peering_connection_id = local.network.peering
  }

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fk-gw-a.id
  }

  tags = {
    Name = "${local.env} private"
  }
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private["us-east-1a"].id
  route_table_id = aws_route_table.private-a.id
}
