output "instance_id" {
  value = aws_instance.docker.id
}

output "public_ip" {
  description = "Elastic IP: stays the same across stop/start."
  value       = aws_eip.docker.public_ip
}

output "ssh_command" {
  description = "Works only if you set key_name; otherwise use SSM."
  value       = "ssh -i <PATH_TO_KEY.pem> ubuntu@${aws_eip.docker.public_ip}"
}

output "ssm_command" {
  description = "Keyless shell via Session Manager (needs AWS CLI + Session Manager plugin)."
  value       = "aws ssm start-session --target ${aws_instance.docker.id} --region ${var.aws_region}"
}

output "docker_context_command" {
  description = "Control this remote Docker Engine from your Windows machine."
  value       = "docker context create aws-docker --docker host=ssh://ubuntu@${aws_eip.docker.public_ip} && docker context use aws-docker"
}

output "app_url" {
  value = "http://${aws_eip.docker.public_ip}:8080"
}

output "ecr_repository_url" {
  description = "Push images here; the instance can pull them via its IAM role."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_login_command" {
  description = "Run ON the instance (or locally) to authenticate Docker to ECR."
  value       = "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}

output "pgadmin_url" {
  value = local.pgadmin_url
}

output "kafka_ui_url" {
  value = local.kafka_ui_url
}

output "pgadmin_login" {
  description = "Initial pgAdmin Administrator. Get the password with the command shown."
  value       = "${var.pgadmin_email} / aws ssm get-parameter --region ${var.aws_region} --with-decryption --name ${local.ssm_prefix}/PGADMIN_DEFAULT_PASSWORD --query Parameter.Value --output text"
}

output "pgadmin_users_passwords" {
  description = "Passwords for var.pgadmin_users (email:Role:password;...)."
  value       = "aws ssm get-parameter --region ${var.aws_region} --with-decryption --name ${local.ssm_prefix}/PGADMIN_EXTRA_USERS --query Parameter.Value --output text"
}

output "postgres_jdbc_url" {
  description = "For apps on any machine (user/password from app_users_passwords)."
  value       = "jdbc:postgresql://${local.db_host}:5432/appdb?sslmode=verify-full&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory"
}

output "kafka_bootstrap_servers" {
  description = "For apps on any machine: SASL_SSL + SCRAM-SHA-512 (user/password from app_users_passwords)."
  value       = "${local.broker_host}:9094"
}

output "app_users_passwords" {
  description = "Credentials for var.app_users (name:role:password;...), same for Postgres and Kafka."
  value       = "aws ssm get-parameter --region ${var.aws_region} --with-decryption --name ${local.ssm_prefix}/APP_USERS --query Parameter.Value --output text"
}

output "public_stack_command" {
  description = "Run ON the instance to start the public stack."
  value       = "cd ~/Docker_Demo/docker-stacks/public && ./fetch-env.sh && docker compose up -d --build"
}
