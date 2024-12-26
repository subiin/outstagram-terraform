# modules/rds-prd/asm.tf

# password를 자동 변경하는 Secret Manger 생성
resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id          = var.secret_arn
  rotate_immediately = var.rotate_immediately

  rotation_rules {
    automatically_after_days = var.automatically_after_days
    duration                 = var.duration
    schedule_expression      = var.schedule_expression
  }
}