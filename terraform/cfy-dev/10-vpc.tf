resource "aws_vpc" "cfy-dev" {
  cidr_block           = "10.254.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "cfy-dev"
  }
}

resource "aws_internet_gateway" "cfy-dev" {
  vpc_id = "${aws_vpc.cfy-dev.id}"

  tags {
    Name = "cfy-dev"
  }
}

resource "aws_subnet" "cfy-dev-a" {
  vpc_id                  = "${aws_vpc.cfy-dev.id}"
  cidr_block              = "10.254.0.0/18"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags {
    Name = "cfy-dev-a"
  }
}

resource "aws_db_subnet_group" "cfy-dev" {
  name        = "cfy-dev"
  description = "cfy-dev"
  subnet_ids  = ["${aws_subnet.cfy-dev-a.id}"]

  tags {
    Name = "cfy-dev"
  }
}

resource "aws_route" "public_access" {
  route_table_id         = "${aws_vpc.cfy-dev.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cfy-dev.id}"
}
