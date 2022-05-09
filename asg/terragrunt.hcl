# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=3.5.0".
# Note the extra `/` after the protocol is required for the shorthand
# notation.
terraform {
  source = "../modules/ecs"
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
  ecs_naming_prefix = "eclaassen-lab-ecs"
  eca_vpc_id = 
  ecs_ingress_cidrs = ["174.16.209.15/32"]
  ecs_ec2_key_name = "eclaassen"
  ecs_ec2_ami = "ami-0686851c4e7b1a8e1"
}