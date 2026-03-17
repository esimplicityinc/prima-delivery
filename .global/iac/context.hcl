locals {
  terragrunt_dir = get_terragrunt_dir()

  version    = yamldecode(file(find_in_parent_folders("version.yaml"))).version
  account_id = try(get_aws_account_id(), "local")

  environment_file   = fileexists("${local.terragrunt_dir}/environment.yaml")   ? "${local.terragrunt_dir}/environment.yaml"   : find_in_parent_folders("environment.yaml")
  system_file        = fileexists("${local.terragrunt_dir}/system.yaml")        ? "${local.terragrunt_dir}/system.yaml"        : find_in_parent_folders("system.yaml")
  sub_system_file    = fileexists("${local.terragrunt_dir}/sub_system.yaml")    ? "${local.terragrunt_dir}/sub_system.yaml"    : find_in_parent_folders("sub_system.yaml")
  stack_file         = fileexists("${local.terragrunt_dir}/stack.yaml")         ? "${local.terragrunt_dir}/stack.yaml"         : find_in_parent_folders("stack.yaml")

  environment_config    = yamldecode(file(local.environment_file))
  system_config_raw     = yamldecode(file(local.system_file))
  sub_system_config_raw = yamldecode(file(local.sub_system_file))
  stack_config_raw      = yamldecode(file(local.stack_file))

  environment = trimspace(try(local.environment_config.environment, local.environment_config.metadata.environment))
  env_details = yamldecode(file(find_in_parent_folders(".global/iac/${local.environment}.yaml")))
  region      = trimspace(local.env_details.region)

  system_name = trimspace(try(
    local.system_config_raw.metadata.name,
    local.system_config_raw.system_name,
    local.system_config_raw.name,
    ""
  ))
  sub_system_name = trimspace(try(
    local.sub_system_config_raw.metadata.name,
    local.sub_system_config_raw.subSystemName,
    local.sub_system_config_raw.sub_system_name,
    local.sub_system_config_raw.name,
    ""
  ))
  stack_name = trimspace(try(
    local.stack_config_raw.metadata.name,
    local.stack_config_raw.stackName,
    local.stack_config_raw.stack_name,
    local.stack_config_raw.name,
    ""
  ))

  # IAM role configuration (aligned with katalyst)
  admin_role           = local.env_details.admin_role
  assume_role          = local.env_details.assume_role
  permissions_boundary = local.env_details.permissions_boundary

  # Environment-specific values
  domain_name         = local.env_details.domain_name
  hosted_zone_id      = local.env_details.hosted_zone_id
  acm_certificate_arn = local.env_details.acm_certificate_arn
}

generate "context" {
  path      = "context.yaml"
  if_exists = "overwrite"
  contents  = <<EOF
    version:              ${local.version}
    account_id:           ${local.account_id}
    region:               ${local.region}
    system_name:          ${local.system_name}
    sub_system_name:      ${local.sub_system_name}
    stack_name:           ${local.stack_name}
    environment:          ${local.environment}
    assume_role:          "arn:aws:iam::${local.account_id}:role/${local.assume_role}"
    admin_role:           "arn:aws:iam::${local.account_id}:role/${local.admin_role}"
    permissions_boundary: ${local.permissions_boundary}
    domain_name:          ${local.domain_name}
    hosted_zone_id:       ${local.hosted_zone_id}
    acm_certificate_arn:  ${local.acm_certificate_arn}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  provider "aws" {
    region = "${local.region}"
    default_tags {
      tags = {
        system_name     = "${local.system_name}"
        sub_system_name = "${local.sub_system_name}"
        stack_name      = "${local.stack_name}"
        environment     = "${local.environment}"
        version         = "${local.version}"
        iac             = "terraform"
      }
    }
  }
  EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  terraform {
    required_version = "~> 1.13"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
  }
  EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt                     = true
    bucket                      = "591639515130-prima-cicd-bootstrap-dev-tf-state"
    key                         = "${local.system_name}/${local.sub_system_name}/${local.stack_name}/${local.environment}/terraform.tfstate"
    region                      = "us-east-1"
    dynamodb_table              = "591639515130-prima-cicd-bootstrap-dev-tf-state-lock"
    disable_bucket_update       = true
    skip_credentials_validation = local.version == "localstack" ? true : false
    skip_metadata_api_check     = local.version == "localstack" ? true : false
    force_path_style            = local.version == "localstack" ? true : false
    access_key                  = local.version == "localstack" ? "mock_access_key" : null
    secret_key                  = local.version == "localstack" ? "mock_secret_key" : null
    endpoint                    = local.version == "localstack" ? "http://s3.localhost.localstack.cloud:4566" : null
    dynamodb_endpoint           = local.version == "localstack" ? "http://localstack:4566" : null
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
