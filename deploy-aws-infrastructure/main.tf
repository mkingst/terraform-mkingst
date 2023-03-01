provider "aws" {
  region = var.region
  }

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable region {}
variable avail_zone {}
variable env_prefix {}

//to use a variable inside a string, use ${}

resource "aws_vpc" "mkingst-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "mkingst-subnet-1" {
  vpc_id = aws_vpc.mkingst-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

//to give the resource sin the VPC access to the internet, add a new route table and IG
//internal traffic in the VPC is confogured automatically

resource "aws_internet_gateway" "mkingst-igw" {
  vpc_id = aws_vpc.mkingst-vpc.id
    tags = {
      Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "mkingst-route-table" {
  vpc_id = aws_vpc.mkingst-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mkingst-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

//we need our subnets associated with the route table that has the internet gateway
//otherwise they are associated with the main route table, which is not a good idea

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.mkingst-subnet-1.id
  route_table_id = aws_route_table.mkingst-route-table.id
}

//now all resources we create will be handled by this route table
//why can't we just use the default route table? we can, using aws_default_route_table resource

resource "aws_security_group" "mkingst-wg" {
  name = "mkingst-sg"
  vpc_id = aws_vpc.mkingst-vpc.id

 // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    //source
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 90
    cidr_blocks = ["0.0.0.0/0"]
  }

  //to allow requests to leave he VPC , eg to fetch docker images
  egress {
    from_port       = 0
    to_port         = 0
    //all protocols
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name: "${var.env_prefix}-sg"
    }
}
