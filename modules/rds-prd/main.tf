# modules/rds-prd/main.tf

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.application}-${var.environment}-db"

  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  db_name  = var.db_name
  port     = 3306

  username = "user"
  manage_master_user_password = true

  # IAM 데이터베이스 인증 활성화
  iam_database_authentication_enabled = true

  # rds_security_group 모듈에서 생성한 보안 그룹 참조
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  # RDS 인스턴스의 CloudWatch 모니터링 설정
  monitoring_interval    = var.monitoring_interval
  monitoring_role_name   = "${var.application}-${var.environment}-db-monitoring-role"
  create_monitoring_role = true

  # RDS 인스턴스가 배치될 서브넷 그룹 설정
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids

  # DB 엔진 패밀리 및 버전 설정
  family = "${var.engine}${var.engine_version}"
  major_engine_version = "${var.engine_version}"

  deletion_protection = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}