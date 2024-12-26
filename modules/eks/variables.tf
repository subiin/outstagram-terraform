# modules/eks/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Cluster version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where EKS worker nodes will be deployed"
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of subnet IDs where EKS worker nodes will be deployed"
  type        = list(string)
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enable_irsa = true"
  type        = string
}

variable "namespaces" {
  description = "Kubernetes namespaces to be deployed"
  type = list(string)
}

variable "db_instance_address" {
  description = "The address of the RDS instance"
  type = string
}

variable "secret_hosted_zone_id" {
  description = "Zone ID of Route53 zone"
  type = string
}