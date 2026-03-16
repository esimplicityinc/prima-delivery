variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider (set false if it already exists in the account)"
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider (required when create_oidc_provider is false)"
  type        = string
  default     = ""
}

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "github_subjects" {
  description = "List of GitHub OIDC subject claims to allow (e.g. repo:org/repo:ref:refs/heads/main)"
  type        = list(string)
}

variable "s3_bucket_arns" {
  description = "ARNs of S3 buckets the deploy role can write to"
  type        = list(string)
}

variable "cloudfront_distribution_arns" {
  description = "ARNs of CloudFront distributions the deploy role can invalidate"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
