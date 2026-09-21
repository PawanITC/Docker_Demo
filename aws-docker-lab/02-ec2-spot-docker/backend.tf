# Remote state in S3 with native locking (no DynamoDB => no extra cost).
# Backend settings are supplied at init time by the CI/CD pipeline:
#   terraform init \
#     -backend-config="bucket=$TF_STATE_BUCKET" \
#     -backend-config="key=aws-docker-lab/02-ec2-spot-docker/terraform.tfstate" \
#     -backend-config="region=$AWS_REGION" \
#     -backend-config="use_lockfile=true"
terraform {
  backend "s3" {}
}
