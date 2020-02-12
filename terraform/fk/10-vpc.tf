resource "aws_vpc" "fk" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
	Name = "fk"
  }
}

resource "aws_internet_gateway" "fk" {
  vpc_id = aws_vpc.fk.id

  tags = {
	Name = "fk"
  }
}

resource "aws_subnet" "fk-a" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.0.0.0/18"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
	Name = "fk-a"
  }
}

resource "aws_subnet" "fk-b" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.0.64.0/18"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
	Name = "fk-b"
  }
}

resource "aws_subnet" "fk-c" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.0.128.0/18"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
	Name = "fk-c"
  }
}

resource "aws_subnet" "fk-e" {
  vpc_id                  = aws_vpc.fk.id
  cidr_block              = "10.0.192.0/18"
  availability_zone       = "us-east-1e"
  map_public_ip_on_launch = true

  tags = {
	Name = "fk-e"
  }
}

resource "aws_route" "public_access" {
  route_table_id         = aws_vpc.fk.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fk.id
}
