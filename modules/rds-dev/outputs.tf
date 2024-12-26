# modules/rds-dev/outputs.tf

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}
output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db.db_instance_name
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db.db_instance_engine
}