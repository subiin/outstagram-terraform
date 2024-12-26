# modules/ecr/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "repository_name" {
  description = "Repository name"
  type = string
}

variable "tag" {
  description = "Tags to apply to the repository"
  type        = string
}

variable "subjects" {
  description = "Tags to apply to the repository"
  type        = list(string)
}