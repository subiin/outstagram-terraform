# modules/rds-prd/sg.tf

# RDS Security Group
module "rds_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.application}-${var.environment}-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow MySQL traffic from EKS"
      cidr_blocks = var.vpc_cidr_block
    }
  ]
}