# modules/s3/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
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