# =============================================================================
#  01 · EC2 + Docker Engine  —  the simplest, most flexible option.
# -----------------------------------------------------------------------------
#  Windows laptop --(SSH / docker context)--> EC2 --> Docker Engine --> containers
#
#  COST (ap-south-1, approximate — always verify in the AWS pricing calculator):
#    - t4g.micro On-Demand: ~$0.0084/hr  => ~$6/month IF left running 24x7.
#    - 20 GB gp3 root:      ~$1.60/month.
#    - Public IPv4:         ~$0.005/hr    => ~$3.6/month while running.
#    ---------------------------------------------------------------------------
#    CHEAPEST WAY TO RUN THIS STACK: t4g.micro and STOP the instance when idle
#    (per-second billing, 60s minimum). A few hours/day of lab use is a few
#    cents/day. New accounts: a t3.micro/t2.micro 750 hrs/mo free tier may apply.
#    For an even cheaper compute price, see stack 02 (EC2 Spot, up to ~90% off).
# =============================================================================

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---- VPC + public networking (Internet Gateway, no NAT => no NAT cost) -------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc", Project = var.project }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw", Project = var.project }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-public", Project = var.project }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project}-public-rt", Project = var.project }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---- Security group: SSH + app + http, all locked to your IP -----------------
resource "aws_security_group" "docker" {
  name        = "${var.project}-sg"
  description = "Docker EC2 lab"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "App (Spring Boot etc.)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-sg", Project = var.project }
}

# ---- Latest Ubuntu 24.04 ARM64 AMI ------------------------------------------
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---- IAM role so you can connect via SSM even without an SSH key -------------
resource "aws_iam_role" "ec2" {
  name = "${var.project}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Project = var.project }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ---- The EC2 instance (installs Docker via user-data) ------------------------
resource "aws_instance" "docker" {
  ami                    = data.aws_ami.ubuntu_arm.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.docker.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
    docker --version
  EOF

  tags = { Name = var.project, Project = var.project }
}
