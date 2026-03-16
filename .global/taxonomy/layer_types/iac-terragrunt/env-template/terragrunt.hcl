include "context" {
  path   = find_in_parent_folders("./.global/iac/context.hcl")
  expose = "true"
}

locals {
  context = yamldecode(include.context.generate.context.contents)
  module  = find_in_parent_folders("./composite/terraform")
}

terraform {
  source = "${local.module}//"
}

inputs = {
  context = local.context
  # add additional module inputs here
}

