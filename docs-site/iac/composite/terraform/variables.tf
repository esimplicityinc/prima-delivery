###############################################################################
# Variables for docs-site infrastructure
###############################################################################

variable "context" {
  description = "Taxonomy context passed from Terragrunt"
  type = object({
    version              = string
    account_id           = string
    region               = string
    system_name          = string
    sub_system_name      = string
    stack_name           = string
    environment          = string
    assume_role          = string
    admin_role           = string
    permissions_boundary = string
    domain_name          = string
    hosted_zone_id       = string
    acm_certificate_arn  = string
  })
}

variable "domain_name" {
  description = "The fully-qualified domain name for the site (e.g. delivery.dev.alvisprima.com or delivery.alvisprima.com)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format for OIDC trust"
  type        = string
  default     = "esimplicityinc/prima-delivery"
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider (set to false if it already exists in the account)"
  type        = bool
  default     = false
}
