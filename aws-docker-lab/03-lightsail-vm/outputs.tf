output "public_ip" {
  value = aws_lightsail_instance.docker.public_ip_address
}

output "username" {
  value = aws_lightsail_instance.docker.username
}

output "ssh_command" {
  value = "ssh ${aws_lightsail_instance.docker.username}@${aws_lightsail_instance.docker.public_ip_address}"
}

output "app_url" {
  value = "http://${aws_lightsail_instance.docker.public_ip_address}:8080"
}

output "ecr_repository_url" {
  description = "Push images here. Private pulls on this Lightsail VM need manual AWS credentials (no instance role)."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_login_command" {
  description = "Run ON the VM after `aws configure` (IAM user with ECR read) to authenticate Docker to ECR."
  value       = "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}
