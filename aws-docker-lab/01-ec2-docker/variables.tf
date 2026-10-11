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

variable "pgadmin_email" {
  type        = string
  description = "Login email for the initial pgAdmin Administrator (password is generated; see outputs)."
  default     = "admin@pgadmin.org"
}

variable "kafka_users" {
  type        = map(string)
  description = "Kafka UI users: email => Cognito group (kafka-admins or kafka-viewers). Each gets an invite email."
  default     = {}

  validation {
    condition     = alltrue([for g in values(var.kafka_users) : contains(["kafka-admins", "kafka-viewers"], g)])
    error_message = "Each kafka_users value must be \"kafka-admins\" or \"kafka-viewers\"."
  }
}

variable "pgadmin_users" {
  type        = map(string)
  description = "Extra pgAdmin users: email => role (Administrator or User). Passwords are generated and stored in SSM."
  default     = {}

  validation {
    condition     = alltrue([for r in values(var.pgadmin_users) : contains(["Administrator", "User"], r)])
    error_message = "Each pgadmin_users value must be \"Administrator\" or \"User\"."
  }
}

variable "app_users" {
  type        = map(string)
  description = "Java/Spring Boot apps that connect to Postgres (5432) and Kafka (9094) from anywhere: name => readwrite or readonly. One generated password per app, stored in SSM."
  default     = {}

  validation {
    condition     = alltrue([for r in values(var.app_users) : contains(["readwrite", "readonly"], r)])
    error_message = "Each app_users value must be \"readwrite\" or \"readonly\"."
  }
  # The name becomes a Postgres role and a Kafka user, so keep it simple.
  validation {
    condition = alltrue([for n in keys(var.app_users) :
    can(regex("^[a-z][a-z0-9_]{2,30}$", n)) && !contains(["postgres", "app_readwrite", "app_readonly"], n)])
    error_message = "app_users names must match ^[a-z][a-z0-9_]{2,30}$ (lowercase, digits, _) and must not be postgres, app_readwrite or app_readonly."
  }
}
