# =============================================================================
#  05 · ECS + Fargate  —  AWS-native serverless containers (no EC2, no daemon).
# -----------------------------------------------------------------------------
#  You do NOT get a Docker daemon to control. Flow: build -> ECR -> ECS task
#  definition -> service -> Fargate task. This stack also creates an ECR repo
#  for your own images and runs a public image by default so it works instantly.
#
#  COST (ap-south-1, approximate):
#    - Fargate 0.25 vCPU + 0.5 GB, 24x7: ~$9/month (vCPU ~$0.011/hr + mem ~$0.0012/GB-hr).
#    - Public IPv4 on the task: ~$3.6/month while running.
#    - CloudWatch Logs + data transfer: usually cents for a lab.
#    ---------------------------------------------------------------------------
#    CHEAPEST WAY: keep the task at 256/512, do NOT add an ALB, and DESTROY the
#    service when idle (Fargate has no "stopped" state — you pay while a task
#    runs). For always-on tiny workloads, EC2 (stack 01/02) is usually cheaper;
#    Fargate wins on zero server management and on bursty/scheduled workloads.
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

# ---- Networking (public subnet + IGW, no NAT => no NAT cost) -----------------
resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc", Project = var.project }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project}-public", Project = var.project }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw", Project = var.project }
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

resource "aws_security_group" "ecs" {
  name   = "${var.project}-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "App"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Project = var.project }
}

# ---- ECR repo for your own images -------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "${var.project}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # let `terraform destroy` remove it even with images
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = var.project }
}

# ---- ECS cluster + logs ------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"
  tags = { Project = var.project }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7 # short retention keeps log cost tiny
  tags              = { Project = var.project }
}

# ---- Task execution role -----------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project}-ecs-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Project = var.project }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---- Task definition ---------------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "app"
      }
    }
  }])
}

# ---- Service -----------------------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true # required for a public-subnet task with no NAT
  }
}
