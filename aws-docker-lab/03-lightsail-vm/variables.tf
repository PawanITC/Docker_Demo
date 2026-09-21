variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "docker-lab-lightsail"
}

variable "bundle_id" {
  type        = string
  description = "Lightsail plan. nano_3_0 is the cheapest."
  default     = "nano_3_0"
}

variable "blueprint_id" {
  type    = string
  default = "ubuntu_24_04"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH, e.g. 49.x.x.x/32."
}
