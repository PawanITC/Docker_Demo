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

variable "github_repo" {
  type        = string
  description = "owner/repo that is allowed to assume the CI role, e.g. PawanITC/Docker_Demo"
  default     = "PawanITC/Docker_Demo"
}
