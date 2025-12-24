provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  # Only set endpoints when running under LocalStack
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  endpoints {
    ec2     = var.use_localstack ? var.localstack_endpoint : null
    ecr     = var.use_localstack ? var.localstack_endpoint : null
    ecs     = var.use_localstack ? var.localstack_endpoint : null
    elbv2   = var.use_localstack ? var.localstack_endpoint : null
    iam     = var.use_localstack ? var.localstack_endpoint : null
    sts     = var.use_localstack ? var.localstack_endpoint : null
    route53 = var.use_localstack ? var.localstack_endpoint : null
    s3      = var.use_localstack ? var.localstack_endpoint : null
  }
}
