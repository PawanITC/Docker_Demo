# =============================================================================
#  02 · EC2 SPOT + Docker Engine  —  the CHEAPEST compute of all these stacks.
# -----------------------------------------------------------------------------
#  Identical to stack 01 except the instance is purchased as SPOT capacity.
#
#  COST (ap-south-1, approximate — Spot prices float with demand):
#    - t4g.micro Spot: often ~$0.002-0.003/hr  => up to ~90% cheaper than
#      On-Demand. Plus ~$1.60/mo gp3 disk and ~$3.6/mo public IPv4 while running.
#    ---------------------------------------------------------------------------
#    CHEAPEST OVERALL for a throwaway Docker lab. The trade-off: AWS can
#    INTERRUPT the instance when it needs capacity (with a short warning). We set
#    interruption_behavior = "stop" so the EBS root volume + data survive; you
#    just start it again. Good for dev/test/batch — NOT for anything that cannot
#    tolerate interruption (production DBs, always-on services).
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

resource "aws_security_group" "docker" {
  name        = "${var.project}-sg"
  description = "Docker EC2 Spot lab"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "App"
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

data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"]
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

resource "aws_instance" "docker" {
  ami                    = data.aws_ami.ubuntu_arm.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.docker.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # ---- This is the only real difference from stack 01: buy Spot capacity. ----
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop" # keep the EBS volume on interrupt
      spot_instance_type             = "persistent"
    }
  }

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
