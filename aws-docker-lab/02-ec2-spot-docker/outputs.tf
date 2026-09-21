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
