###############################################################################
# Outputs for docs-site infrastructure
###############################################################################

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the site"
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidation)"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_url" {
  description = "Full URL of the deployed site"
  value       = "https://${var.domain_name}"
}

output "github_deploy_role_arn" {
  description = "ARN of the IAM role for GitHub Actions deployment"
  value       = aws_iam_role.github_deploy.arn
}

output "environment" {
  description = "Environment this layer was deployed to"
  value       = var.context.environment
}

output "region" {
  description = "Region used for deployment"
  value       = var.context.region
}
