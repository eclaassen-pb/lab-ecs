# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=3.5.0".
# Note the extra `/` after the protocol is required for the shorthand
# notation.

terraform {
  source = "../modules/efs"
}

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-west-2"
}
EOF
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnets = ["subnet-id"]
    vpc_id = "vpc-id"
  }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  efs_naming_prefix = "eclaassen-lab"
  efs_vpc_id = dependency.vpc.outputs.vpc_id
  efs_subnet_ids = dependency.vpc.outputs.private_subnets
}