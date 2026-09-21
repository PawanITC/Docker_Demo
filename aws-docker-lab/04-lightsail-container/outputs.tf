output "service_url" {
  description = "Managed HTTPS endpoint for the container service."
  value       = aws_lightsail_container_service.app.url
}

output "service_state" {
  value = aws_lightsail_container_service.app.state
}
