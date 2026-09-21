output "service_url" {
  description = "Managed HTTPS endpoint for the container service."
  value       = aws_lightsail_container_service.app.url
}

output "service_state" {
  value = aws_lightsail_container_service.app.state
}

output "ecr_repository_url" {
  description = "Push images here; set container_image to <this>:<tag> and re-apply. The service pulls via its Lightsail image-puller role."
  value       = aws_ecr_repository.app.repository_url
}
