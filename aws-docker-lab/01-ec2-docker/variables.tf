variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "docker-lab"
}

variable "instance_type" {
  type    = string
  default = "t4g.micro" # ARM64. Use t3.micro if your images are x86-only.
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH / reach the app, e.g. 49.x.x.x/32. NEVER 0.0.0.0/0."
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name for SSH. Leave empty to use SSM-only access."
  default     = ""
}

variable "root_volume_size" {
  type    = number
  default = 20
}
