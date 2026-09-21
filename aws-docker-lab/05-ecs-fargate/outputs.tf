output "ecr_repository_url" {
  description = "Push your own image here, then set container_image to <this>:<tag>."
  value       = aws_ecr_repository.app.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "find_task_ip" {
  description = "The Fargate task gets a public IP; look it up after deploy."
  value       = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --region ${var.aws_region}"
}

output "force_new_deployment" {
  description = "Re-pull :latest after pushing a new image with the same tag."
  value       = "aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.app.name} --force-new-deployment --region ${var.aws_region}"
}
