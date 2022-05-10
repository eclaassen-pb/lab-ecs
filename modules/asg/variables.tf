variable "asg_naming_prefix" {
  description = "Naming prefix for ASG resources"
  type        = string
}

variable "asg_subnet_ids" {
  description = "Subnet IDs for the ASG"
  type        = list
}

variable "asg_vpc_id" {
  description = "The VPC ID for the ASG"
  type        = string
}

variable "asg_ingress_cidrs {
  description = "Ingress CIDRs for the instances the ASG creates"
}