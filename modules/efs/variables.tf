variable "efs_naming_prefix" {
  description = "Naming prefix for EFS resources"
  type        = string
}

variable "efs_subnet_ids" {
  description = "Subnet IDs for EFS"
  type        = list
}

variable "efs_vpc_id" {
  description = "The VPC ID for EFS"
  type        = string
}