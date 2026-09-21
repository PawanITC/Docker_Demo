# =============================================================================
#  03 · Lightsail VM + Docker Engine  —  simplest, flat predictable price.
# -----------------------------------------------------------------------------
#  A managed Ubuntu VM with a bundled fixed monthly price that INCLUDES a static
#  IP and a data-transfer allowance. You SSH in and use Docker exactly like EC2.
#
#  COST (flat, published):
#    - nano_3_0 bundle: ~$3.50/month (first month often free) — CHEAPEST here.
#    - next size (micro_3_0): ~$5/month.
#  Fixed pricing = no surprise IPv4/egress line items, unlike EC2. Trade-off:
#  less flexible than EC2 for wider AWS learning.
#
#  NOTE: Docker is NOT preinstalled. Install it once after first boot:
#    sudo apt update && sudo apt install -y docker.io
#    sudo systemctl enable --now docker && sudo usermod -aG docker ubuntu
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

resource "aws_lightsail_instance" "docker" {
  name              = var.project
  availability_zone = "${var.aws_region}a"
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id

  # Install Docker on first boot so the VM is ready to use.
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
  EOF

  tags = { Project = var.project }
}

# ---- Private ECR repo to hold your own images --------------------------------
# NOTE: a Lightsail VM has NO IAM instance role, so it cannot pull a PRIVATE ECR
# image automatically. To pull from this repo on the VM you must give it AWS
# credentials manually, e.g. create an IAM user with AmazonEC2ContainerRegistryReadOnly,
# then on the box: `aws configure` (paste keys), then the ecr_login_command below.
# For public images (Docker Hub, public ECR) no credentials are needed.
resource "aws_ecr_repository" "app" {
  name         = var.project
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Project = var.project }
}

# Open the ports we need (Lightsail has its own firewall, separate from VPC SGs).
resource "aws_lightsail_instance_public_ports" "docker" {
  instance_name = aws_lightsail_instance.docker.name

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = [var.ssh_cidr]
  }
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidrs     = [var.ssh_cidr]
  }
  port_info {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    cidrs     = [var.ssh_cidr]
  }
}
