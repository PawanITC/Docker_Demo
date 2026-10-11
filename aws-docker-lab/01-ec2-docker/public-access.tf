# =============================================================================
#  Public access: pgAdmin + Kafka UI for anyone with a login, over HTTPS, and
#  Postgres + Kafka for Java/Spring Boot apps on any machine.
# -----------------------------------------------------------------------------
#  Internet --443--> Caddy (on EC2, Let's Encrypt cert) --> pgAdmin / Kafka UI
#  Internet --5432--> Postgres  (TLS + password, db.<host>)
#  Internet --9094--> Kafka     (SASL_SSL / SCRAM-SHA-512, broker.<host>)
#
#  - Elastic IP:   fixed public address, so the URLs never change.
#  - Hostnames:    <service>.<ip-with-dashes>.sslip.io (free wildcard DNS that
#                  resolves to the IP inside the name; no domain to buy).
#  - pgAdmin:      its own email/password users (Administrator / User roles);
#                  var.pgadmin_users are created by the pgadmin-users container.
#  - Kafka UI:     sign-in with AWS Cognito; access by Cognito group
#                  (kafka-admins = full control, kafka-viewers = read-only).
#  - Secrets:      written to SSM Parameter Store; the instance reads them via
#                  its IAM role (docker-stacks/public/fetch-env.sh).
#  - App users:    var.app_users => one Postgres role + one Kafka user per app,
#                  same generated password (created by the postgres-users /
#                  kafka-users containers).
#  - Public ports: 80/443, 5432, 9094 (see the security group in main.tf).
#
#  COST: Elastic IP is billed like any public IPv4 (~$3.6/month, same as now).
#        Cognito is free up to 10,000 monthly active users.
# =============================================================================

resource "aws_eip" "docker" {
  instance = aws_instance.docker.id
  domain   = "vpc"
  tags     = { Name = "${var.project}-eip", Project = var.project }
}

locals {
  public_host  = "${replace(aws_eip.docker.public_ip, ".", "-")}.sslip.io"
  pgadmin_url  = "https://pgadmin.${local.public_host}"
  kafka_ui_url = "https://kafka.${local.public_host}"
  db_host      = "db.${local.public_host}"     # Postgres, TLS cert from Caddy
  broker_host  = "broker.${local.public_host}" # Kafka EXTERNAL listener
  ssm_prefix   = "/${var.project}/public"
}

# ---- Cognito: who may sign in to Kafka UI ------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_cognito_user_pool" "kafka_ui" {
  name                     = "${var.project}-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Invite-only: users are added by Terraform (var.kafka_users), no self sign-up.
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = { Project = var.project }
}

# Hosted sign-in page: https://<prefix>.auth.<region>.amazoncognito.com
resource "aws_cognito_user_pool_domain" "kafka_ui" {
  domain       = "${var.project}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.kafka_ui.id
}

resource "aws_cognito_user_pool_client" "kafka_ui" {
  name            = "kafka-ui"
  user_pool_id    = aws_cognito_user_pool.kafka_ui.id
  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["${local.kafka_ui_url}/login/oauth2/code/cognito"]
  logout_urls                          = [local.kafka_ui_url, "${local.kafka_ui_url}/"]
}

resource "aws_cognito_user_group" "kafka" {
  for_each     = toset(["kafka-admins", "kafka-viewers"])
  name         = each.key
  user_pool_id = aws_cognito_user_pool.kafka_ui.id
}

# Each user gets an email from Cognito with a temporary password.
resource "aws_cognito_user" "kafka" {
  for_each     = var.kafka_users
  user_pool_id = aws_cognito_user_pool.kafka_ui.id
  username     = each.key

  attributes = {
    email          = each.key
    email_verified = true
  }
  desired_delivery_mediums = ["EMAIL"]
}

resource "aws_cognito_user_in_group" "kafka" {
  for_each     = var.kafka_users
  user_pool_id = aws_cognito_user_pool.kafka_ui.id
  username     = aws_cognito_user.kafka[each.key].username
  group_name   = aws_cognito_user_group.kafka[each.value].name
}

# ---- Generated passwords ------------------------------------------------------
resource "random_password" "pgadmin" {
  length  = 24
  special = false
}

resource "random_password" "postgres" {
  length  = 24
  special = false
}

resource "random_password" "pgadmin_user" {
  for_each = var.pgadmin_users
  length   = 24
  special  = false
}

resource "random_password" "app_user" {
  for_each = var.app_users
  length   = 32
  special  = false
}

# Protects the PKCS12 keystore Kafka reads its TLS cert from.
resource "random_password" "tls_keystore" {
  length  = 24
  special = false
}

# ---- Runtime config for the containers, read by fetch-env.sh -----------------
locals {
  public_env = {
    PUBLIC_HOST              = local.public_host
    PGADMIN_DEFAULT_EMAIL    = var.pgadmin_email
    PGADMIN_DEFAULT_PASSWORD = random_password.pgadmin.result
    # "email:Role:password;..." for the pgadmin-users container ("-" = none;
    # SSM does not allow empty values).
    PGADMIN_EXTRA_USERS = coalesce(join(";", [
      for email, role in var.pgadmin_users : "${email}:${role}:${random_password.pgadmin_user[email].result}"
    ]), "-")
    POSTGRES_PASSWORD = random_password.postgres.result
    # "name:role:password;..." for the postgres-users / kafka-users containers.
    APP_USERS = coalesce(join(";", [
      for name, role in var.app_users : "${name}:${role}:${random_password.app_user[name].result}"
    ]), "-")
    TLS_KEYSTORE_PASSWORD = random_password.tls_keystore.result
    COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.kafka_ui.id
    COGNITO_CLIENT_SECRET = aws_cognito_user_pool_client.kafka_ui.client_secret
    COGNITO_ISSUER_URI    = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.kafka_ui.id}"
    COGNITO_LOGOUT_URL    = "https://${aws_cognito_user_pool_domain.kafka_ui.domain}.auth.${var.aws_region}.amazoncognito.com/logout"
  }
}

resource "aws_ssm_parameter" "public_env" {
  for_each = local.public_env
  name     = "${local.ssm_prefix}/${each.key}"
  type     = "SecureString"
  value    = each.value
  tags     = { Project = var.project }
}

# Let the instance read (only) its own config parameters.
resource "aws_iam_role_policy" "read_public_env" {
  name = "${var.project}-read-public-env"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParametersByPath", "ssm:GetParameters", "ssm:GetParameter"]
      Resource = [
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}",
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/*",
      ]
    }]
  })
}
