provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  # Only set endpoints when running under LocalStack
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
   endpoints {
    ec2                   = var.use_localstack ? var.localstack_endpoint : ""
    ecr                   = var.use_localstack ? var.localstack_endpoint : ""
    ecs                   = var.use_localstack ? var.localstack_endpoint : ""
    elbv2                 = var.use_localstack ? var.localstack_endpoint : ""
    iam                   = var.use_localstack ? var.localstack_endpoint : ""
    sts                   = var.use_localstack ? var.localstack_endpoint : ""
    route53               = var.use_localstack ? var.localstack_endpoint : ""
    s3                    = var.use_localstack ? var.localstack_endpoint : ""
    applicationautoscaling= var.use_localstack ? var.localstack_endpoint : ""
    cloudwatch            = var.use_localstack ? var.localstack_endpoint : ""
}


  

}
