# Root terragrunt.hcl — shared configuration for all environments
#
# This file is included automatically by child terragrunt.hcl files via
# find_in_parent_folders().

locals {
  # Parse the environment from the directory path: infra/terragrunt/<env>/...
  env = regex("terragrunt/([^/]+)/", path_relative_to_include())[0]
}

# Remote state — single S3 backend for all environments, keyed by path
remote_state {
  backend = "s3"

  config = {
    bucket         = "591639515130-prima-cicd-bootstrap-dev-tf-state"
    key            = "prima-delivery/${local.env}/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "591639515130-prima-cicd-bootstrap-dev-tf-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate the AWS provider block for every child module
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "us-east-1"

      default_tags {
        tags = {
          ManagedBy   = "terragrunt"
          Project     = "prima-delivery"
          Environment = "${local.env}"
          Repository  = "esimplicityinc/prima-delivery"
        }
      }
    }
  EOF
}

# Common inputs inherited by all children
inputs = {
  aws_region = "us-east-1"
}
