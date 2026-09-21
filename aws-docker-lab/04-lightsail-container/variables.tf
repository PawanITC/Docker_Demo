variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "docker-lab-container"
}

variable "power" {
  type        = string
  description = "Container service size. nano is cheapest."
  default     = "nano"
}

variable "scale" {
  type    = number
  default = 1
}

variable "container_image" {
  type        = string
  description = "Public image to deploy. For a private image, push it first with the Lightsail plugin and reference it here."
  default     = "nginx:latest"
}

variable "container_port" {
  type    = number
  default = 80
}
