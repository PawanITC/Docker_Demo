output "instance_id" {
  value = aws_instance.docker.id
}

output "public_ip" {
  value = aws_instance.docker.public_ip
}

output "ssh_command" {
  value = "ssh -i <PATH_TO_KEY.pem> ubuntu@${aws_instance.docker.public_ip}"
}

output "ssm_command" {
  value = "aws ssm start-session --target ${aws_instance.docker.id} --region ${var.aws_region}"
}

output "docker_context_command" {
  value = "docker context create aws-docker --docker host=ssh://ubuntu@${aws_instance.docker.public_ip} && docker context use aws-docker"
}

output "app_url" {
  value = "http://${aws_instance.docker.public_ip}:8080"
}

output "ecr_repository_url" {
  description = "Push images here; the instance can pull them via its IAM role."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_login_command" {
  description = "Run ON the instance (or locally) to authenticate Docker to ECR."
  value       = "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}
