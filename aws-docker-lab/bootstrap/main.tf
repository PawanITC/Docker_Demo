# =============================================================================
#  BOOTSTRAP  —  run this ONCE, locally, before using the CI/CD pipeline.
# -----------------------------------------------------------------------------
#  Creates the two things every other stack + the GitHub Actions pipeline need:
#    1. An S3 bucket that holds Terraform remote state (so `apply` in one CI run
#       and `destroy` in a later run share the same state).
#    2. A GitHub OIDC provider + IAM role that the workflow ASSUMES — no
#       long-lived AWS access keys are ever stored in GitHub.
#
#  COST: essentially free.
#    - S3 state bucket: a few KB of versioned objects => well under $0.01/month.
#    - OIDC provider + IAM role: $0.00 (IAM is free).
#    - No lock table needed: we use S3-native locking (use_lockfile), so there
#      is NO DynamoDB cost. This is the CHEAPEST possible state backend.
#
#  This stack uses LOCAL state (committed nowhere — see .gitignore). That is
#  intentional: it avoids the chicken-and-egg problem of needing a state bucket
#  to create the state bucket.
# =============================================================================

terraform {
  required_version = ">= 1.10.0" # 1.10+ required for S3-native state locking
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

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# 1. Remote state bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
  tags   = { Project = var.project, Purpose = "terraform-remote-state" }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# 2. GitHub OIDC provider (create once per AWS account)
# -----------------------------------------------------------------------------
# If your account already has this provider, import it instead of recreating:
#   terraform import aws_iam_openid_connect_provider.github \
#     arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = { Project = var.project }
}

# -----------------------------------------------------------------------------
# 3. IAM role the GitHub Actions workflow assumes
# -----------------------------------------------------------------------------
# Trust is locked to YOUR repo. `sub` uses a wildcard on the ref so any branch
# can run the manual workflow; tighten to a specific branch/environment for prod.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = "${var.project}-gha-terraform"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = { Project = var.project }
}

# For a lab we grant AdministratorAccess so every stack (EC2, Lightsail, ECS,
# ECR, IAM) can be created AND destroyed. For production, replace this with a
# least-privilege policy scoped to only the services/resources you use.
resource "aws_iam_role_policy_attachment" "gha_admin" {
  role       = aws_iam_role.gha.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
