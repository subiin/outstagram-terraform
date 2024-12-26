# modules/efs/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enable_irsa = true"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "The ARN of the IAM Role created for EBS CSI Driver IRSA."
  type        = string
}