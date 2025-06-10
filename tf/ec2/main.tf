provider "aws" {
  region = "ap-south-1"
}

# Filter Key Pair
data "aws_key_pair" "github_actions_key" {
  filter {
    name   = "key-name"
    values = ["github-actions-key"]
  }
}

# Filter VPC
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

# Filter Public Subnet
data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }
}

# Filter Private Subnet
data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }
}

# Filter Amazon Linux 2023 AMI by Owner and Name
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["137112412989"] # Amazon's official account ID for Amazon Linux in ap-south-1
}

# Public EC2 Instance
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.public_subnet.id
  key_name                    = data.aws_key_pair.github_actions_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "Public-EC2"
  }
}

# Private EC2 Instance
resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.private_subnet.id
  key_name                    = data.aws_key_pair.github_actions_key.key_name
  associate_public_ip_address = false

  tags = {
    Name = "Private-EC2"
  }
}
