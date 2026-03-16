# Prod environment — static-site module
#
# Deploys S3 + CloudFront + ACM + Route53 for alvisprima.com

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/static-site"
}

inputs = {
  bucket_name            = "prima-delivery-docs-prod"
  domain_name            = "alvisprima.com"
  hosted_zone_name       = "alvisprima.com"
  cloudfront_price_class = "PriceClass_100"

  tags = {
    Environment = "prod"
    Service     = "docs"
  }
}
