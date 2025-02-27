# modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of cidr_blocks of public subnets"
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of cidr_blocks of private subnets"
  value = module.vpc.private_subnets
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value = module.vpc.default_security_group_id
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value = module.vpc.private_subnets_cidr_blocks
}