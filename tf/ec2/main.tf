
provider "aws" {
  region = "us-east-1"
}

# Fetch Key Pair
data "aws_key_pair" "github_actions_key" {
  filter {
    name   = "key-name"
    values = ["github-actions-key-*"]
  }
}

output "selected_key_name" {
  value = data.aws_key_pair.github_actions_key.key_name
}

# Fetch VPC
data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

# Fetch Public Subnet
data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
}

# Fetch Private Subnet
data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
}

# Fetch Security Group
data "aws_security_group" "example_sg" {
  filter {
    name   = "group-name"
    values = ["example-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
}

# Fetch Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"] # Amazon official
}

# Public EC2 instance
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.public_subnet.id
  vpc_security_group_ids      = [data.aws_security_group.example_sg.id]
  key_name                    = data.aws_key_pair.github_actions_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "Public-EC2"
  }
}

# Private EC2 instance
resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.private_subnet.id
  vpc_security_group_ids      = [data.aws_security_group.example_sg.id]
  key_name                    = data.aws_key_pair.github_actions_key.key_name
  associate_public_ip_address = false

  tags = {
    Name = "Private-EC2"
  }
}
