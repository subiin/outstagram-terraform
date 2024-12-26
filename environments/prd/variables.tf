# environments/prd/variables.tf

## COMMON
variable "application" {
  description = "Application name"
  type        = string
  default     = "outstagram"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prd"
}

## VPC
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

## EKS
variable "public_access_cidrs" {
  description = "List of subnet IDs where EKS worker nodes will be deployed"
  type        = list(string)
}

variable "namespaces" {
  description = "Kubernetes namespaces to be deployed"
  type = list(string)
  default = ["infra", "sns", "argocd", "monitoring"]
}

## S3
variable "namespace" {
  description = "The Kubernetes namespace where the service account is located"
  type = string
  default = "kube-system"
}

variable "service_account" {
  description = "The name of the Kubernetes service account"
  type = string
  default = "loki-sa"
}

## RDS
variable "engine" {
  description = "The database engine to use"
  type = string
  default = "mysql"
}

variable "engine_version" {
  description = "The engine version to use"
  type = string
  default = "8.0"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type = string
  default = "db.m5d.large"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type = 	number
  default = 20
}

variable "storage_type" {
  description = "The allocated storage in gigabytes"
  type = 	string
  default = "gp3"
}

variable "username" {
  description = "Username for the master DB user"
  type = string
  default = "admin"
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type = string
  default = "3306"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type = string
  default = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled"
  type = string
  default = "03:00-06:00"
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type = number
  default = 30
}

variable "rotate_immediately" {
  description = "Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window."
  type = bool
  default = true
}

variable "automatically_after_days" {
  description = "Specifies the number of days between automatic scheduled rotations of the secret. Either automatically_after_days or schedule_expression must be specified."
  type = number
  default = null
}

variable "duration" {
  description = "The length of the rotation window in hours. For example, 3h for a three hour window."
  type = string
  default = "3h"
}

variable "schedule_expression" {
  description = "A cron() or rate() expression that defines the schedule for rotating your secret. Either automatically_after_days or schedule_expression must be specified."
  type = string
  default = "rate(4 hour)"
}

## ECR
variable "ecr_repositories" {
  description = "List of ECR repositories to create with their tags"
  type = map(string)
  default = {
    "feed-server"     = "f_"
    "image-server"    = "i_"
    "sns-frontend"    = "s_"
    "timeline-server" = "t_"
    "user-server"     = "u_"
  }
}

variable "subjects" {
  description = "Tags to apply to the repository"
  type        = list(string)
  default     = ["subiin/outstagram-application:*"]
}

## Route 53
variable "zone_names" {
  type = map(object({
    comment = string
    tags    = map(string)
  }))
  default = {
    "outstagram.shop" = {
      comment = "Prd environment for outstagram.shop"
      tags    = {
        service       = "outstagram"
        environment   = "prd"
      }
    }
  }
}

## ACM
variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type = string
  default = "outstagram.shop"
}

variable "validation_method" {
  description = "Which method to use for validation. DNS or EMAIL are valid"
  type = string
  default = "DNS"
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type = list(string)
  default = [
    "*.outstagram.shop"
  ]
}