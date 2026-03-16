# Prod environment — github-oidc module
#
# Creates a deploy role for the prod docs site.
# Re-uses the OIDC provider created by the dev environment (only one per account).

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/github-oidc"
}

dependency "static_site" {
  config_path = "../static-site"

  mock_outputs = {
    s3_bucket_arn              = "arn:aws:s3:::prima-delivery-docs-prod"
    cloudfront_distribution_arn = "arn:aws:cloudfront::591639515130:distribution/MOCK"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  # The OIDC provider already exists from the dev environment.
  # Set to false and provide the existing ARN to avoid a duplicate resource error.
  create_oidc_provider      = false
  existing_oidc_provider_arn = "arn:aws:iam::591639515130:oidc-provider/token.actions.githubusercontent.com"

  role_name = "prima-delivery-docs-deploy-prod"

  # Prod deploys only on tag push / release
  github_subjects = [
    "repo:esimplicityinc/prima-delivery:ref:refs/tags/*",
  ]

  s3_bucket_arns              = [dependency.static_site.outputs.s3_bucket_arn]
  cloudfront_distribution_arns = [dependency.static_site.outputs.cloudfront_distribution_arn]

  tags = {
    Environment = "prod"
    Service     = "docs"
  }
}
