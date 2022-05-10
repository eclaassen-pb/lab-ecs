# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=3.5.0".
# Note the extra `/` after the protocol is required for the shorthand
# notation.
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=3.5.0"
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

# Indicate the input values to use for the variables of the module.
inputs = {
  name = "eclaassen-lab-vpc"
  cidr = "10.101.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.101.1.0/24", "10.101.2.0/24", "10.101.3.0/24"]
  public_subnets  = ["10.101.101.0/24", "10.101.102.0/24", "10.101.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform    = "true"
    Environment  = "lab"
  }
}