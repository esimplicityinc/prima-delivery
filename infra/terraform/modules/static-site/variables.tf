variable "bucket_name" {
  description = "Name of the S3 bucket for the static site"
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain name for the site (e.g. dev.alvisprima.com)"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (e.g. dev.alvisprima.com or alvisprima.com)"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
