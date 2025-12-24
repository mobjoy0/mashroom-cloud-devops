variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "use_localstack" {
  type    = bool
  default = true
}

variable "localstack_endpoint" {
  type    = string
  default = "http://localhost:4566"
}

variable "image" {
  type    = string
  description = "ECR repository URI for LocalStack Pro (e.g., 000000000000.dkr.ecr.us-east-1.amazonaws.com/mashroom-app:latest)"
  default = "000000000000.dkr.ecr.us-east-1.amazonaws.com/mashroom-app:latest"
}

variable "container_port" {
  type    = number
  default = 3000
}
