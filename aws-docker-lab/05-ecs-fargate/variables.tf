variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "docker-lab-fargate"
}

variable "task_cpu" {
  type        = string
  description = "Fargate CPU units. 256 (0.25 vCPU) is the smallest/cheapest."
  default     = "256"
}

variable "task_memory" {
  type        = string
  description = "Fargate memory (MiB). 512 is the smallest for 256 CPU."
  default     = "512"
}

variable "container_image" {
  type        = string
  description = "Image to run. Defaults to a public image so it works with no ECR push. Point at your ECR repo for your own app."
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "ingress_cidr" {
  type        = string
  description = "CIDR allowed to reach the task, e.g. 49.x.x.x/32."
}
