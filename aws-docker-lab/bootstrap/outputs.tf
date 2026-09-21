output "state_bucket" {
  description = "Set this as GitHub repo variable TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.id
}

output "gha_role_arn" {
  description = "Set this as GitHub repo variable AWS_ROLE_ARN"
  value       = aws_iam_role.gha.arn
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "next_steps" {
  value = <<-EOT
    1. In GitHub → repo → Settings → Secrets and variables → Actions → Variables, add:
         AWS_ROLE_ARN    = ${aws_iam_role.gha.arn}
         TF_STATE_BUCKET = ${aws_s3_bucket.state.id}
         AWS_REGION      = ${var.aws_region}
         SSH_CIDR        = <your.public.ip>/32   (for EC2 SSH; use x.x.x.x/32, never 0.0.0.0/0)
       (optional) EC2_KEY_NAME = <existing EC2 key pair name>  — leave unset to use SSM-only access
    2. Run the "Terraform Infra Control" workflow from the Actions tab.
  EOT
}
