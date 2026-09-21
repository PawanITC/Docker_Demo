variable "aws_region" {
  type    = string
  default = "ap-south-1" # Mumbai
}

variable "project" {
  type    = string
  default = "docker-lab"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for Terraform remote state, e.g. docker-lab-tfstate-<your-account-id>"
}

# This becomes the OIDC trust `sub` pattern: repo:${github_repo}:*
# NOTE: if your org/enterprise customizes the OIDC "subject claim" to include
# immutable numeric IDs, the token's sub is
#   repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/<branch>
# and you MUST set github_repo to the ID-augmented form, e.g.
#   "PawanITC@239576472/Docker_Demo@1361482141"
# Otherwise "owner/repo" is correct. To see your actual sub, run a workflow with
# id-token: write and decode the token payload (see repo history: oidc-debug).
variable "github_repo" {
  type        = string
  description = "GitHub sub identity allowed to assume the CI role. Plain 'owner/repo', OR 'owner@<owner_id>/repo@<repo_id>' if the org customizes the OIDC subject claim."
  default     = "PawanITC/Docker_Demo"
}
