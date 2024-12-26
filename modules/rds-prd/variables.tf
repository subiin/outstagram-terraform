# modules/rds-prd/variables.tf

variable "application" {
  description = "Application name"
  type = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type = string
}

variable "engine_version" {
  description = "The engine version to use"
  type = string
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
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type = 	string
  default = "gp3"
}

variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type = string
  default = "sns"
}

variable "username" {
  description = "Username for the master DB user"
  type = string
  default = "admin"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type = string
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled"
  type = string
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type = number
}

variable "secret_arn" {
  description = "The ARN of the master user secret"
  type = string
}

variable "rotate_immediately" {
  description = "Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window."
  type = bool
}

variable "automatically_after_days" {
  description = "Specifies the number of days between automatic scheduled rotations of the secret. Either automatically_after_days or schedule_expression must be specified."
  type = number
}

variable "duration" {
  description = "The length of the rotation window in hours. For example, 3h for a three hour window."
  type = string
}

variable "schedule_expression" {
  description = "A cron() or rate() expression that defines the schedule for rotating your secret. Either automatically_after_days or schedule_expression must be specified."
  type = string
}