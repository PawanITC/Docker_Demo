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
