# =============================================================================
#  04 · Lightsail Container Service  —  "just run my image", no server to manage.
# -----------------------------------------------------------------------------
#  There is NO VM and NO Docker daemon you control. You give Lightsail a Docker
#  image and it runs it, with a managed HTTPS endpoint. Simpler than ECS/Fargate.
#
#  COST (flat, published; billed while the service exists):
#    - nano power, scale 1: ~$7/month (prorated hourly) — CHEAPEST option here.
#    - Deleting the service stops billing; there is no cheaper "stopped" state,
#      so DESTROY it when you are done (the CI/CD destroy action does this).
#
#  This example deploys a PUBLIC image (nginx) so it works with no image push.
#  For your own app: build locally, then
#    aws lightsail push-container-image --service-name <svc> --label app --image myapp:latest
#  and set container_image to the ":app.x" reference Lightsail prints.
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

# ---- Private ECR repo to hold your own images --------------------------------
resource "aws_ecr_repository" "app" {
  name         = var.project
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Project = var.project }
}

resource "aws_lightsail_container_service" "app" {
  name        = var.project
  power       = var.power
  scale       = var.scale
  is_disabled = false
  tags        = { Project = var.project }

  # Let this service pull PRIVATE images from ECR. Lightsail creates a managed
  # "image puller" IAM principal; we grant it pull access on the repo below.
  private_registry_access {
    ecr_image_puller_role {
      is_active = true
    }
  }
}

# Allow the Lightsail image-puller principal to pull from this ECR repo.
resource "aws_ecr_repository_policy" "lightsail_pull" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowLightsailPull"
      Effect    = "Allow"
      Principal = { AWS = aws_lightsail_container_service.app.private_registry_access[0].ecr_image_puller_role[0].principal_arn }
      Action = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability",
      ]
    }]
  })
}

resource "aws_lightsail_container_service_deployment_version" "app" {
  service_name = aws_lightsail_container_service.app.name

  container {
    container_name = "app"
    image          = var.container_image
    ports = {
      (tostring(var.container_port)) = "HTTP"
    }
  }

  public_endpoint {
    container_name = "app"
    container_port = var.container_port
    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout_seconds     = 5
      interval_seconds    = 10
      path                = "/"
      success_codes       = "200-499"
    }
  }
}
