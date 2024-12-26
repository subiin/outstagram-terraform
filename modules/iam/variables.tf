# modules/iam/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "subjects" {
  description = "Tags to apply to the repository"
  type        = list(string)
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enable_irsa = true"
  type        = string
}