# Dev environment — github-oidc module
#
# Creates the GitHub OIDC provider and a deploy role for the dev docs site.
# The role is scoped to the dev S3 bucket and CloudFront distribution.

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/github-oidc"
}

dependency "static_site" {
  config_path = "../static-site"

  mock_outputs = {
    s3_bucket_arn              = "arn:aws:s3:::prima-delivery-docs-dev"
    cloudfront_distribution_arn = "arn:aws:cloudfront::591639515130:distribution/MOCK"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  create_oidc_provider = true
  role_name            = "prima-delivery-docs-deploy-dev"

  github_subjects = [
    "repo:esimplicityinc/prima-delivery:ref:refs/heads/main",
  ]

  s3_bucket_arns              = [dependency.static_site.outputs.s3_bucket_arn]
  cloudfront_distribution_arns = [dependency.static_site.outputs.cloudfront_distribution_arn]

  tags = {
    Environment = "dev"
    Service     = "docs"
  }
}
