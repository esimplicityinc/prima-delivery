# Dev environment — static-site module
#
# Deploys S3 + CloudFront + ACM + Route53 for dev.alvisprima.com

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/static-site"
}

inputs = {
  bucket_name            = "prima-delivery-docs-dev"
  domain_name            = "dev.alvisprima.com"
  hosted_zone_name       = "dev.alvisprima.com"
  cloudfront_price_class = "PriceClass_100"

  tags = {
    Environment = "dev"
    Service     = "docs"
  }
}
