#!/usr/bin/env bash
# Writes .env for docker compose from SSM Parameter Store (created by Terraform
# in aws-docker-lab/01-ec2-docker/public-access.tf). Uses the instance role, so
# no AWS keys are needed. Re-run after every `terraform apply`.
set -euo pipefail
cd "$(dirname "$0")"

PREFIX="${1:-/docker-lab/public}"
TOKEN=$(curl -sf -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
REGION="${AWS_REGION:-$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)}"

umask 077
aws ssm get-parameters-by-path --region "$REGION" --path "$PREFIX" --with-decryption \
  --query "Parameters[].[Name,Value]" --output text |
  while IFS=$'\t' read -r name value; do
    printf "%s='%s'\n" "${name##*/}" "$value"
  done > .env

echo "Wrote $(wc -l < .env) settings to $(pwd)/.env"
grep -E '^PUBLIC_HOST=' .env | sed "s/PUBLIC_HOST='\(.*\)'/pgAdmin:  https:\/\/pgadmin.\1\nKafka UI: https:\/\/kafka.\1\nPostgres: db.\1:5432 (TLS)\nKafka:    broker.\1:9094 (SASL_SSL)/"
