# modules/vpc/variables.tf

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}