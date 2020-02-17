locals {
  top_cidr = "${lookup(var.workspace_to_network_map, terraform.workspace, "")}"
  network_a_cidr = "${lookup(var.workspace_to_network_a_map, terraform.workspace, "")}"
  network_b_cidr = "${lookup(var.workspace_to_network_b_map, terraform.workspace, "")}"
  network_c_cidr = "${lookup(var.workspace_to_network_c_map, terraform.workspace, "")}"
  network_e_cidr = "${lookup(var.workspace_to_network_e_map, terraform.workspace, "")}"
  azs = var.network.dev.azs
}

resource "aws_vpc" "fk" {
  cidr_block           = local.top_cidr
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


resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = local.azs[0]
  tags = {
	Name = "${local.env} public a"
  }
}
resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = local.azs[1]
  tags = {
	Name = "${local.env} public b"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.3.0/24"
  availability_zone       = local.azs[2]
  tags = {
	Name = "${local.env} public c"
  }
}
resource "aws_subnet" "public-e" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.4.0/24"
  availability_zone       = local.azs[3]
  tags = {
	Name = "${local.env} public e"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.5.0/24"
  availability_zone       = local.azs[0]

  tags = {
	Name = "${local.env} a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.6.0/24"
  availability_zone       = local.azs[1]

  tags = {
	Name = "${local.env} b"
  }
}

resource "aws_subnet" "private-c" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.7.0/24"
  availability_zone       = local.azs[2]

  tags = {
	Name = "${local.env} c"
  }
}

resource "aws_subnet" "private-e" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.1.8.0/24"
  availability_zone       = local.azs[3]

  tags = {
	Name = "${local.env} e"
  }
}

resource "aws_route" "public_access" {
  route_table_id         = aws_vpc.fk.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fk.id
}

resource "aws_db_subnet_group" "fk" {
  name        = "${local.env}-db"
  description = "${local.env}-db"
  subnet_ids  = [ aws_subnet.private-a.id, aws_subnet.private-b.id, aws_subnet.private-c.id, aws_subnet.private-e.id ]

  tags = {
	Name = local.env
  }
}

resource "aws_eip" "gw-a" {
}

resource "aws_nat_gateway" "fk-gw-a" {
  allocation_id = aws_eip.gw-a.id
  subnet_id     = aws_subnet.public-a.id
  depends_on    = [ aws_internet_gateway.fk ]

  tags = {
	Name = "${local.env} gateway"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = aws_vpc.fk.id

  route {
    cidr_block = "172.31.0.0/16"
	vpc_peering_connection_id = var.peering_connection_id
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
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-a.id
}
