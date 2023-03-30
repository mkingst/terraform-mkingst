provider "aws" {
  region = var.region
  }

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable region {}
variable avail_zone {}
variable env_prefix {}
variable instance_type {}
variable public_key_location {}

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

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}


resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.mkingst-subnet-1.id
    vpc_security_group_ids = [aws_security_group.mkingst-wg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    tags = {
          Name: "${var.env_prefix}-server"
    }
}
