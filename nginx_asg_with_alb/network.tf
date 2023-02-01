resource "aws_vpc" "vpc_nginx" {
  cidr_block           = var.vpc["cidr"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.app_name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.vpc_nginx.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

	tags = {
    Name = var.app_name
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.vpc_nginx.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

	tags = {
    Name = var.app_name
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_nginx.id

  tags = {
    Name = var.app_name
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc_nginx.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_security_group" "elb_security_group" {
  name        = "elb_security_group"
  description = "Allow TLS inbound traffic on port 80 (http)"
  vpc_id      = aws_vpc.vpc_nginx.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "security_group_ec2"
  description = "Allow ec2 ssh and http/s"
  vpc_id      = aws_vpc.vpc_nginx.id

  dynamic "ingress" {
    for_each = var.ec2_instance.open_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
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
}

resource "aws_eip" "nginx_eip" {
  instance = aws_instance.hello_world.id
  vpc      = true
}